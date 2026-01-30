const std = @import("std");
const c = @import("window.zig").c;
const RenderCommand = @import("render_command.zig").RenderCommand;
const Color = @import("render_command.zig").Color;

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
    renderer.pushClearBackground(color);
}

export fn rect(
    renderer: *Renderer,
    pos: Vec2,
    size: Vec2,
    color: Color,
) callconv(.c) void {
    renderer.pushDrawRectangle(pos.x, pos.y, size.x, size.y, color);
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
    renderer.pushDrawText(text_ptr[0..text_len], x, y, size, color);
}

export fn loadTexture(renderer: *Renderer, path: [*]const u8) callconv(.c) *c.Texture2D {
    _ = renderer;
    const texture_ptr = std.heap.c_allocator.create(c.Texture2D) catch unreachable;
    texture_ptr.* = c.loadTexture(path); // Maiúsculo!
    std.debug.print("📸 Loaded: {any}\n", .{texture_ptr.*});
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
    std.debug.print("🎨 Drawing texture: {any}\n", .{texture});
    c.drawTexturePro(texture, source, dest, origin, rotation, tint);
}

pub const Renderer = struct {
    commands: std.ArrayList(RenderCommand),

    pub fn init(
        allocator: std.mem.Allocator,
        capacity: usize,
    ) !Renderer {
        return .{
            .commands = try std.ArrayList(RenderCommand)
                .initCapacity(allocator, capacity),
        };
    }

    pub fn deinit(self: *Renderer, allocator: std.mem.Allocator) void {
        self.commands.deinit(allocator);
    }

    pub fn clear(self: *Renderer) void {
        self.commands.clearRetainingCapacity();
    }

    pub fn execute(self: *Renderer) void {
        for (self.commands.items) |cmd| {
            switch (cmd) {
                .clear_background => |clear_cmd| {
                    c.clearBackground(toRaylibColor(clear_cmd.color));
                },
                .draw_rectangle => |rect_cmd| {
                    c.drawRectangle(
                        rect_cmd.x,
                        rect_cmd.y,
                        rect_cmd.width,
                        rect_cmd.height,
                        toRaylibColor(rect_cmd.color),
                    );
                },
                .draw_text => |text_cmd| {
                    c.drawText(
                        text_cmd.text[0..text_cmd.text_len :0],
                        text_cmd.x,
                        text_cmd.y,
                        text_cmd.size,
                        toRaylibColor(text_cmd.color),
                    );
                },
            }
        }
    }

    // ===== Internal Push API =====

    pub fn pushClearBackground(
        self: *Renderer,
        color: Color,
    ) void {
        self.commands.appendAssumeCapacity(.{
            .clear_background = .{ .color = color },
        });
    }

    pub fn pushDrawRectangle(
        self: *Renderer,
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        color: Color,
    ) void {
        self.commands.appendAssumeCapacity(.{
            .draw_rectangle = .{
                .x = x,
                .y = y,
                .width = width,
                .height = height,
                .color = color,
            },
        });
    }

    pub fn pushDrawText(
        self: *Renderer,
        txt: []const u8,
        x: f32,
        y: f32,
        size: f32,
        color: Color,
    ) void {
        const len = @min(txt.len, 256);
        var text_buffer: [256]u8 = undefined;
        @memcpy(text_buffer[0..len], txt[0..len]);

        self.commands.appendAssumeCapacity(.{
            .draw_text = .{
                .text = text_buffer,
                .text_len = len,
                .x = x,
                .y = y,
                .size = size,
                .color = color,
            },
        });
    }
};

fn toRaylibColor(color: Color) c.Color {
    return .{
        .r = color.r,
        .g = color.g,
        .b = color.b,
        .a = color.a,
    };
}
