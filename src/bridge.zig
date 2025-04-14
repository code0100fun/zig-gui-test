const std = @import("std");
const WebView = @import("webview").WebView;
const lib = @import("gui_test_lib");

pub const Context = struct {
    webview: *align(8) WebView,
    arena: *std.heap.ArenaAllocator,
};

const Zigui = struct {
    context: Context,
};

const WebViewCallback = fn (seq: [:0]const u8, req: [:0]const u8, userdata: ?*anyopaque) void;

fn CallbackType(comptime T: type, comptime ResultT: type) type {
    return fn (ctx: *Context, arg: T) anyerror!ResultT;
}

pub fn create() !Zigui {
    // Allocate the arena on the heap so it persists
    var arena_ptr = try std.heap.page_allocator.create(std.heap.ArenaAllocator);
    arena_ptr.* = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    const allocator = arena_ptr.allocator();

    // Allocate the WebView with proper alignment
    var webview_ptr = try allocator.create(WebView);
    webview_ptr.* = WebView.create(true, null);

    const ctx = Context{
        .webview = webview_ptr,
        .arena = arena_ptr,
    };

    // Set window properties
    try webview_ptr.setTitle("GUI Test");
    try webview_ptr.setSize(800, 600, WebView.WindowSizeHint.None);

    return Zigui{
        .context = ctx,
    };
}

pub fn run(self: *Zigui) !void {
    try self.context.webview.navigate("http://localhost:5175");
    try self.context.webview.run();
}

pub fn destroy(self: *Zigui) !void {
    // First destroy the webview
    try self.context.webview.destroy();

    // Then free the arena allocator which will free the webview memory
    self.context.arena.deinit();

    // Free the arena pointer itself
    std.heap.page_allocator.destroy(self.context.arena);
}

pub fn bind(self: *Zigui, name: []const u8, callback: anytype) !void {
    // Create a wrapper for the callback that handles WebView-specific boilerplate
    const wrappedCallback = createCallbackWrapper(callback);

    // Create a callback context with our wrapped callback
    const callback_ctx = WebView.CallbackContext(&wrappedCallback).init(@constCast(&self.context));
    const callback_ptr = try self.context.arena.allocator().create(@TypeOf(callback_ctx));
    callback_ptr.* = callback_ctx;

    // Make sure the string is null-terminated
    const name_z = try std.fmt.allocPrintZ(self.context.arena.allocator(), "{s}", .{name});
    try self.context.webview.bind(name_z, callback_ptr);
}

fn inferCallbackTypes(comptime callback: anytype) struct { T: type, ResultT: type } {
    const Fn = @TypeOf(callback);
    const type_info = @typeInfo(Fn);
    const fn_info = @field(type_info, "fn");

    return .{
        .T = fn_info.params[1].type.?,
        .ResultT = @typeInfo(fn_info.return_type.?).error_union.payload,
    };
}

// Generic callback wrapper that handles WebView-specific boilerplate
fn createCallbackWrapper(comptime callback: anytype) WebViewCallback {
    const types = inferCallbackTypes(callback);
    const T = types.T;
    // const ResultT = types.ResultT;

    return struct {
        fn wrapper(seq: [:0]const u8, req: [:0]const u8, userdata: ?*anyopaque) void {
            var ctx: *Context = @ptrCast(@alignCast(userdata));
            const allocator = ctx.arena.allocator();

            // Parse the JSON request
            var str = std.mem.trimLeft(u8, req, "[\"");
            str = std.mem.trimRight(u8, str, "\"]\n");

            const payload = std.mem.replaceOwned(
                u8,
                allocator,
                str,
                "\\\"",
                "\"",
            ) catch unreachable;
            defer allocator.free(payload);

            // Parse the value from the JSON
            const parsed = std.json.parseFromSlice(
                T,
                allocator,
                payload,
                .{},
            ) catch |err| {
                std.debug.print("Failed to parse JSON: {any}\n", .{err});
                ctx.webview.ret(seq, 1, "{\"error\": \"Failed to parse request\"}"[0.. :0]) catch unreachable;
                return;
            };
            defer parsed.deinit();

            std.debug.print("Request: {any}\n", .{parsed.value});

            // Call the user-provided callback
            const result = callback(ctx, parsed.value) catch |err| {
                std.debug.print("Error in callback: {any}\n", .{err});
                ctx.webview.ret(seq, 1, "{\"error\": \"Failed to call callback\"}"[0.. :0]) catch unreachable;
                return;
            };

            const response = std.json.stringifyAlloc(
                allocator,
                result,
                .{
                    .whitespace = .minified,
                },
            ) catch "{\"error\": \"Failed to create response\"}";
            defer allocator.free(response);

            const response_z = std.fmt.allocPrintZ(
                allocator,
                "{s}",
                .{response},
            ) catch "{\"error\": \"Failed to create response\"}"[0.. :0];
            defer allocator.free(response_z);

            std.debug.print("Response: {s}\n", .{response_z});

            // Return the result
            ctx.webview.ret(seq, 0, response_z) catch |err| {
                std.debug.print("Error returning result: {any}\n", .{err});
            };
        }
    }.wrapper;
}
