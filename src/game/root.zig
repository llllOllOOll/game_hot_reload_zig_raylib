const std = @import("std");
const c = @import("zraylib");

const GameState = struct {
    counter: u64 = 0,
    // Existing animated rectangle
    rect_x: f32 = 1.0,
    rect_y: f32 = 1.0,
    direction: f32 = 2.0,
    rect_width: f32 = 50.0,
    rect_height: f32 = 50.0,

    // Player entity - CORRIGIDO
    player_x: f32 = 640.0, // Centro horizontal (1280/2)
    player_y: f32 = 360.0, // Centro vertical (720/2)
    player_size: f32 = 40.0, // AUMENTADO para 40x40 pixels
    player_speed: f32 = 5.0,
};

pub export fn game_update(memory: [*]u8, memory_size: usize, window_width: f32, window_height: f32) void {
    _ = memory_size;

    const state = @as(*GameState, @ptrCast(@alignCast(memory)));

    if (state.counter == 0) {
        // Inicializa com valores padrão na primeira execução
        state.* = GameState{};
        std.debug.print("Game initialized - Window: {}x{}\n", .{ window_width, window_height });
        std.debug.print("Player initialized at: ({d:.1}, {d:.1})\n", .{ state.player_x, state.player_y });
    }

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

    // Debug output
    if (state.counter % 60 == 0) {
        std.debug.print("Frame: {}, RedRect_X: {d:.1}, Player_X: {d:.1}, Player_Y: {d:.1}\n", .{ state.counter, state.rect_x, state.player_x, state.player_y });
    }

    // Player movement
    const move_speed = state.player_speed;
    if (c.isKeyDown(c.KEY_W)) {
        state.player_y -= move_speed;
    }
    if (c.isKeyDown(c.KEY_S)) {
        state.player_y += move_speed;
    }
    if (c.isKeyDown(c.KEY_A)) {
        state.player_x -= move_speed;
    }
    if (c.isKeyDown(c.KEY_D)) {
        state.player_x += move_speed;
    }

    // Boundary clamping
    state.player_x = @max(0, @min(window_width - state.player_size, state.player_x));
    state.player_y = @max(0, @min(window_height - state.player_size, state.player_y));

    c.drawRectangle(state.rect_x, state.rect_y, state.rect_width, state.rect_height, c.RED);
    c.drawRectangle(state.player_x, state.player_y, state.player_size, state.player_size, c.PURPLE);
    c.drawText("FPS: 60", 10.0, 10.0, 20.0, c.YELLOW);

    // // Draw red rectangle (validation) - CORRIGIDO A COR
    // c.drawRectangle(
    //     @intFromFloat(state.rect_x),
    //     @intFromFloat(state.rect_y),
    //     @intFromFloat(state.rect_width),
    //     @intFromFloat(state.rect_height),
    //     c.RED, // MUDADO DE BLUE PARA RED
    // );
    //
    // // Draw player (green for visibility) - MUDADO A COR
    // c.drawRectangle(
    //     @intFromFloat(state.player_x),
    //     @intFromFloat(state.player_y),
    //     @intFromFloat(state.player_size),
    //     @intFromFloat(state.player_size),
    //     c.PURPLE, // VERDE para diferenciar do retângulo vermelho
    // );
}
