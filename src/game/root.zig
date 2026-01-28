const std = @import("std");
const c = @import("platform").c;

const GameState = struct {
    counter: u64 = 0,
    rect_x: f32 = 100.0,
    rect_y: f32 = 200.0,
    direction: f32 = 2.0,
    rect_width: f32 = 50.0,
    rect_height: f32 = 50.0,
};

// pub export fn game_update(memory: [*]u8, memory_size: usize, window_width: i32, window_height: i32) void {
pub export fn game_update(memory: [*]u8, memory_size: usize, window_width: f32, window_height: f32) void {
    _ = memory_size;

    _ = window_height;

    const state = @as(*GameState, @ptrCast(@alignCast(memory)));
    if (state.counter == 0) {
        std.debug.print("Game initialized\n", .{});
    }

    state.counter += 1;

    // Update rectangle position
    state.rect_x += state.direction;

    // Bounce at screen edges
    if (state.rect_x <= 0 or state.rect_x + state.rect_width >= window_width) {
        state.direction *= -1;
    }

    // Debug output every second (60 frames)
    if (state.counter % 60 == 0) {
        std.debug.print("Game frame: {}, rect_x: {}\n", .{ state.counter, state.rect_x });
    }
    // Draw the rectangle
    c.drawRectangle(
        @intFromFloat(state.rect_x),
        @intFromFloat(state.rect_y),
        @intFromFloat(state.rect_width),
        @intFromFloat(state.rect_height),
        c.RED,
    );
}
