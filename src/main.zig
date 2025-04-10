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
    try bridge.bind(&zigui, "incrementCounter", incrementCounter);
    try bridge.bind(&zigui, "getCurrentTime", getCurrentTime);
    try bridge.bind(&zigui, "sendMessageToZig", sendMessageToZig);

    try bridge.run(&zigui);
}

fn incrementCounter(_: *bridge.Context, parsed: IncrementCounterArg) anyerror!IncrementCounterResult {
    // Simply increment the counter and return the new value
    std.debug.print("Incrementing counter: {d}\n", .{parsed.value});
    return IncrementCounterResult{ .result = parsed.value + 1 };
}

fn getCurrentTime(_: *bridge.Context, _: GetCurrentTimeArg) anyerror!GetCurrentTimeResult {
    // Get the current timestamp and return it
    const ms = std.time.milliTimestamp();
    std.debug.print("Current time: {d}\n", .{ms});
    return GetCurrentTimeResult{ .timestamp = ms };
}

fn sendMessageToZig(_: *bridge.Context, parsed: SendMessageToZigArg) anyerror!SendMessageToZigResult {
    // Log the message and return a success status
    std.debug.print("Received message: {s}\n", .{parsed.message});
    return SendMessageToZigResult{ .status = "success", .message = "Message received" };
}
