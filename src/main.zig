const std = @import("std");
const WebView = @import("webview").WebView;
const lib = @import("gui_test_lib");
const bridge = @import("bridge.zig");

const IncrementCounterArg = struct {
    value: u32,
};

const IncrementCounterResult = struct {
    result: u32,
};

const GetCurrentTimeArg = struct {
    // No arguments needed for this function
};

const GetCurrentTimeResult = struct {
    timestamp: i64,
};

const SendMessageToZigArg = struct {
    message: []const u8,
};
const SendMessageToZigResult = struct {
    status: []const u8,
    message: []const u8,
};

pub fn main() !void {
    var zigui = try bridge.create();
    defer bridge.destroy(&zigui) catch unreachable;

    // Register the JavaScript callback with our implementation
    try bridge.bind(&zigui, "toggleValue", toggleValue);
    try bridge.bind(&zigui, "incrementCounter", incrementCounter);
    try bridge.bind(&zigui, "getCurrentTime", getCurrentTime);
    try bridge.bind(&zigui, "sendMessageToZig", sendMessageToZig);
    try bridge.bind(&zigui, "sendStringToZig", sendStringToZig);

    try bridge.run(&zigui);
}

fn toggleValue(_: *bridge.Context, value: bool) anyerror!bool {
    // Simply toggle the value and return the new value
    std.debug.print("Toggling value: {any} to {any}\n", .{ value, !value });
    return !value;
}

fn incrementCounter(_: *bridge.Context, value: u32) anyerror!u32 {
    // Simply increment the counter and return the new value
    std.debug.print("Incrementing counter: {d}\n", .{value});
    return value + 1;
}

fn getCurrentTime(_: *bridge.Context, _: GetCurrentTimeArg) anyerror!GetCurrentTimeResult {
    // Get the current timestamp and return it
    const ms = std.time.milliTimestamp();
    std.debug.print("Current time: {d}\n", .{ms});
    return GetCurrentTimeResult{ .timestamp = ms };
}

fn sendMessageToZig(ctx: *bridge.Context, parsed: SendMessageToZigArg) anyerror!SendMessageToZigResult {
    // Print the message and return a success status
    std.debug.print("Received message: {s}\n", .{parsed.message});
    const message = try std.fmt.allocPrint(ctx.arena.allocator(), "Hello {s}", .{parsed.message});
    return SendMessageToZigResult{ .status = "success", .message = message };
}

fn sendStringToZig(ctx: *bridge.Context, message: []const u8) anyerror![]const u8 {
    // Print the message as a string
    std.debug.print("Received message: {s}\n", .{message});
    return try std.fmt.allocPrint(ctx.arena.allocator(), "Hello {s}", .{message});
}
