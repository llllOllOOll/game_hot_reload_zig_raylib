const std = @import("std");
pub const Platform = @This();
pub const Window = @import("window.zig").Window;
pub const c = @import("window.zig").c;
pub const CommandBuffer = @import("command_buffer.zig").CommandBuffer;
pub const RenderCommand = @import("render_command.zig").RenderCommand;
pub const Color = @import("render_command.zig").Color;
// Re-export common colors for convenience
pub const BLACK = @import("render_command.zig").BLACK;
pub const WHITE = @import("render_command.zig").WHITE;
pub const RED = @import("render_command.zig").RED;
pub const GREEN = @import("render_command.zig").GREEN;
pub const BLUE = @import("render_command.zig").BLUE;
pub const YELLOW = @import("render_command.zig").YELLOW;
pub const PURPLE = @import("render_command.zig").PURPLE;
pub const Config = struct {
    width: i32,
    height: i32,
    title: [:0]const u8,
    resizable: bool,
};
window: Window,
config: Config,
allocator: std.mem.Allocator,
command_buffer: CommandBuffer,
/// Initialize platform, window and render command buffer
pub fn init(
    allocator: std.mem.Allocator,
    config: Config,
) !Platform {
    const window = try Window.init(
        config.title,
        config.width,
        config.height,
        config.resizable,
    );
    // Capacity chosen explicitly (engine decision)
    const command_buffer = try CommandBuffer.init(
        allocator,
        1024, // max render commands per frame
    );
    return .{
        .window = window,
        .config = config,
        .allocator = allocator,
        .command_buffer = command_buffer,
    };
}
pub fn deinit(self: *Platform) void {
    self.command_buffer.deinit(self.allocator);
    self.window.deinit();
}
// ======================================================
// Window delegation
// ======================================================
pub fn setTargetFPS(self: *Platform, fps: i32) void {
    self.window.setTargetFPS(fps);
}
pub fn shouldClose(self: *const Platform) bool {
    return self.window.shouldClose();
}
// ======================================================
// Frame lifecycle
// ======================================================
/// Begin frame:
/// - clear command buffer
/// - start Raylib drawing
pub fn beginFrame(self: *Platform) void {
    self.command_buffer.clear();
    c.beginDrawing();
}
/// End frame:
/// - execute render commands
/// - finish Raylib drawing
pub fn endFrame(self: *Platform) void {
    self.command_buffer.execute();
    c.endDrawing();
}
pub fn pollEvents(self: *Platform) void {
    _ = self;
    // Raylib handles input/events internally for now
}
// ======================================================
// Accessors
// ======================================================
/// Expose command buffer for game code (write-only usage)
pub fn getCommandBuffer(self: *Platform) *CommandBuffer {
    return &self.command_buffer;
}
