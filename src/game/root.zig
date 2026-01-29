const std = @import("std");

// ============================================================
// Structs básicas
// ============================================================

pub const Color = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const BLACK = Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
pub const WHITE = Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
pub const RED = Color{ .r = 255, .g = 0, .b = 0, .a = 255 };

pub const GameState = struct {
    initialized: bool,
    frame_counter: u64,
};

pub const Vec2 = extern struct { x: f32, y: f32 };

pub const Renderer = opaque {
    extern fn clear(self: *Renderer, color: Color) void;
    extern fn rect(self: *Renderer, pos: Vec2, size: Vec2, color: Color) void;
};

// ============================================================
// Exports
// ============================================================

pub export fn game_update(
    memory: [*]u8,
    memory_size: usize,
    window_width: f32,
    window_height: f32,
    renderer: *Renderer,
) callconv(.c) void {
    if (memory_size < @sizeOf(GameState)) return;

    const state = @as(*GameState, @ptrCast(@alignCast(memory)));

    if (!state.initialized) {
        state.* = .{
            .initialized = true,
            .frame_counter = 0,
        };
        std.debug.print("🎮 Inicializado! {d}x{d}\n", .{ window_width, window_height });
    }

    state.frame_counter += 1;

    renderer.clear(BLACK);

    renderer.rect(.{ .x = 100, .y = 100 }, .{ .x = 50, .y = 50 }, RED);

    if (state.frame_counter % 60 == 0) {
        std.debug.print("✅ Frame {}\n", .{state.frame_counter});
    }
}

pub export fn game_on_reload(
    memory: [*]u8,
    memory_size: usize,
) callconv(.c) void {
    if (memory_size < @sizeOf(GameState)) return;

    const state = @as(*GameState, @ptrCast(@alignCast(memory)));
    std.debug.print("🔥 Hot reload! Frame atual: {}\n", .{state.frame_counter});
}
