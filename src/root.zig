//! This is the root source file for the GUI Test library.
const std = @import("std");

// Export the HTML content for the WebView
pub const html = @embedFile("ui/dist/index.html");
