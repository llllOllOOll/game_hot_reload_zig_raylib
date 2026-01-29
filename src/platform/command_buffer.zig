const std = @import("std");
const c = @import("window.zig").c;
const RenderCommand = @import("render_command.zig").RenderCommand;
const Color = @import("render_command.zig").Color;

pub const CommandBuffer = struct {
    commands: std.ArrayList(RenderCommand),

    pub fn init(
        allocator: std.mem.Allocator,
        capacity: usize,
    ) !CommandBuffer {
        return .{
            .commands = try std.ArrayList(RenderCommand)
                .initCapacity(allocator, capacity),
        };
    }

    pub fn deinit(self: *CommandBuffer, allocator: std.mem.Allocator) void {
        self.commands.deinit(allocator);
    }

    pub fn clear(self: *CommandBuffer) void {
        self.commands.clearRetainingCapacity();
    }

    pub fn execute(self: *CommandBuffer) void {
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

    // ===== Push API =====

    pub fn pushClearBackground(
        self: *CommandBuffer,
        color: Color,
    ) void { // Modified by Claude AI: removido '!' porque export não pode retornar erro
        self.commands.appendAssumeCapacity(.{ // Modified by Claude AI: mudado para appendAssumeCapacity
            .clear_background = .{ .color = color },
        });
    }

    pub fn pushDrawRectangle(
        self: *CommandBuffer,
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        color: Color,
    ) void { // Modified by Claude AI: removido '!' porque export não pode retornar erro
        self.commands.appendAssumeCapacity(.{ // Modified by Claude AI: mudado para appendAssumeCapacity
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
        self: *CommandBuffer,
        text: []const u8,
        x: f32,
        y: f32,
        size: f32,
        color: Color,
    ) void { // Modified by Claude AI: removido '!' porque export não pode retornar erro
        var text_buffer: [256]u8 = undefined;
        const len = @min(text.len, text_buffer.len);
        @memcpy(text_buffer[0..len], text[0..len]);

        self.commands.appendAssumeCapacity(.{ // Modified by Claude AI: mudado para appendAssumeCapacity
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

// ======================================================
// Modified by Claude AI: Funções exportadas para o game.so chamar
// ======================================================

// Modified by Claude AI: Export que decompõe Color em componentes RGBA
export fn pushClearBackground(cmd_buf: *CommandBuffer, r: u8, g: u8, b: u8, a: u8) callconv(.c) void {
    cmd_buf.pushClearBackground(.{ .r = r, .g = g, .b = b, .a = a });
}

// Modified by Claude AI: Export que decompõe Color em componentes RGBA
export fn pushDrawRectangle(
    cmd_buf: *CommandBuffer,
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    r: u8,
    g: u8,
    b: u8,
    a: u8,
) callconv(.c) void {
    cmd_buf.pushDrawRectangle(x, y, width, height, .{ .r = r, .g = g, .b = b, .a = a });
}

// Modified by Claude AI: Export que decompõe Color em componentes RGBA
export fn pushDrawText(
    cmd_buf: *CommandBuffer,
    text_ptr: [*]const u8,
    text_len: usize,
    x: f32,
    y: f32,
    size: f32,
    r: u8,
    g: u8,
    b: u8,
    a: u8,
) callconv(.c) void {
    cmd_buf.pushDrawText(text_ptr[0..text_len], x, y, size, .{ .r = r, .g = g, .b = b, .a = a });
}

// Modified by Claude AI: Export para isKeyDown
export fn isKeyDown(key: c_int) callconv(.c) bool {
    return c.isKeyDown(@intCast(key));
}
