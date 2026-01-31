const std = @import("std");

pub const Platform = @This();
pub const Window = @import("window.zig").Window;
pub const c = @import("window.zig").c;
pub const Renderer = @import("renderer.zig").Renderer;

pub const Config = struct {
    width: i32,
    height: i32,
    title: [:0]const u8,
    resizable: bool,
};

window: Window,
config: Config,
allocator: std.mem.Allocator,
renderer: Renderer,

/// Initialize platform, window and renderer
pub fn init(
    config: Config,
) !Platform {
    const window = try Window.init(
        config.title,
        config.width,
        config.height,
        config.resizable,
    );

    // Capacity chosen explicitly (engine decision)
    const renderer = try Renderer.init();

    return .{
        .window = window,
        .config = config,
        .allocator = undefined, // TODO: Pass allocator parameter
        .renderer = renderer,
    };
}

pub fn deinit(self: *Platform) void {
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

pub fn getFrameTime(self: *Platform) f32 {
    _ = self;
    return c.getFrameTime();
}

pub fn beginFrame(self: *Platform) void {
    _ = self;
    c.beginDrawing();
}

pub fn endFrame(self: *Platform) void {
    _ = self;
    c.endDrawing();
}

pub fn pollEvents(self: *Platform) void {
    _ = self;
}

// ======================================================
// Accessors
// ======================================================

/// Expose renderer for game code (write-only usage)
pub fn getRenderer(self: *Platform) *Renderer {
    return &self.renderer;
}
