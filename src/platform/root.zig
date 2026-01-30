const std = @import("std");

pub const Platform = @This();
pub const Window = @import("window.zig").Window;
pub const c = @import("window.zig").c;
pub const Renderer = @import("renderer.zig").Renderer;
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
renderer: Renderer,

/// Initialize platform, window and renderer
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
    const renderer = try Renderer.init(
        allocator,
        1024, // max render commands per frame
    );

    return .{
        .window = window,
        .config = config,
        .allocator = allocator,
        .renderer = renderer,
    };
}

pub fn deinit(self: *Platform) void {
    self.renderer.deinit(self.allocator);
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
    // self.window.getFrameTime();
    _ = self;
    return c.getFrameTime();
}

pub fn beginFrame(self: *Platform) void {
    self.renderer.clear();
    c.beginDrawing();
}

pub fn endFrame(self: *Platform) void {
    self.renderer.execute();
    c.endDrawing();
}

// pub fn loadTexture(self: *Platform, path: [*:0]const u8) c.Texture2D {
//     _ = self;
//     return c.loadTexture(path);
// }
//
// pub fn drawTexture(
//     self: *Platform,
//     texture: c.Texture2D,
//     source: c.Rectangle,
//     dest: c.Rectangle,
//     origin: c.Vector2,
//     rotation: f32,
//     tint: c.Color,
// ) void {
//     _ = self;
//     c.drawTexturePro(texture, source, dest, origin, rotation, tint);
// }

pub fn pollEvents(self: *Platform) void {
    _ = self;
    // Raylib handles input/events internally for now
}

// ======================================================
// Accessors
// ======================================================

/// Expose renderer for game code (write-only usage)
pub fn getRenderer(self: *Platform) *Renderer {
    return &self.renderer;
}
