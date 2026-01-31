const std = @import("std");
const c = @import("window.zig").c;

pub const Renderer = struct {
    pub fn init() !Renderer {
        return .{};
    }
};

/// Color representation independent from Raylib
pub const Color = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

/// Common colors
pub const BLACK = Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
pub const WHITE = Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
pub const RED = Color{ .r = 255, .g = 0, .b = 0, .a = 255 };
pub const GREEN = Color{ .r = 0, .g = 255, .b = 0, .a = 255 };
pub const BLUE = Color{ .r = 0, .g = 0, .b = 255, .a = 255 };
pub const YELLOW = Color{ .r = 255, .g = 255, .b = 0, .a = 255 };
pub const PURPLE = Color{ .r = 200, .g = 122, .b = 255, .a = 255 };

// ======================================================
// Exported C API for game.so
// ======================================================
pub const Vec2 = extern struct { x: f32, y: f32 };
pub const Vec4 = extern struct { x: f32, y: f32, z: f32, w: f32 };

// Hangle input //
export fn isKeyPressed(self: *Renderer, key: i32) callconv(.c) bool {
    _ = self;
    return c.isKeyPressed(key);
}

export fn isKeyDown(self: *Renderer, key: i32) callconv(.c) bool {
    _ = self;
    return c.isKeyDown(key);
}

export fn clear(renderer: *Renderer, color: Color) callconv(.c) void {
    _ = renderer;
    c.clearBackground(toRaylibColor(color));
}

export fn rect(
    renderer: *Renderer,
    pos: Vec2,
    size: Vec2,
    color: Color,
) callconv(.c) void {
    _ = renderer;
    c.drawRectangle(pos.x, pos.y, size.x, size.y, toRaylibColor(color));
}

export fn text(
    renderer: *Renderer,
    text_ptr: [*]const u8,
    text_len: usize,
    x: f32,
    y: f32,
    size: f32,
    color: Color,
) callconv(.c) void {
    _ = renderer;
    const text_slice = text_ptr[0..text_len];
    // Allocate null-terminated string for Raylib
    const text_cstr = std.heap.c_allocator.allocSentinel(u8, text_slice.len, 0) catch unreachable;
    @memcpy(text_cstr[0..text_slice.len], text_slice);
    c.drawText(text_cstr, x, y, size, toRaylibColor(color));
    std.heap.c_allocator.free(text_cstr);
}

export fn loadTexture(renderer: *Renderer, path: [*]const u8) callconv(.c) *c.Texture2D {
    _ = renderer;
    const texture_ptr = std.heap.c_allocator.create(c.Texture2D) catch unreachable;
    texture_ptr.* = c.loadTexture(path);
    std.debug.print("Loaded: {any}\n", .{texture_ptr.*});
    return texture_ptr;
}

export fn unloadTexture(renderer: *Renderer, texture: *c.Texture2D) callconv(.c) void {
    _ = renderer;
    c.unloadTexture(texture.*);
    std.heap.c_allocator.destroy(texture);
}

export fn drawTexture(
    self: *Renderer,
    texture_ptr: *anyopaque,
    source: c.Rectangle,
    dest: c.Rectangle,
    origin: c.Vector2,
    rotation: f32,
    tint: c.Color,
) callconv(.c) void {
    _ = self;
    const texture = @as(*c.Texture2D, @ptrCast(@alignCast(texture_ptr))).*;
    c.drawTexturePro(texture, source, dest, origin, rotation, tint);
}

fn toRaylibColor(color: Color) c.Color {
    return .{
        .r = color.r,
        .g = color.g,
        .b = color.b,
        .a = color.a,
    };
}
