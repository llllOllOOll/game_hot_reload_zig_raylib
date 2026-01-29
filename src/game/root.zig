const std = @import("std");
const Platform = @import("platform").Platform;
const c = Platform.c;

pub const GameState = struct {
    // Hot reload flag
    is_initialized: bool,
    reload_count: u32,

    // Game counters
    counter: u32,

    // Red rectangle (bouncing)
    rect_x: f32,
    rect_y: f32,
    rect_width: f32,
    rect_height: f32,
    direction: f32,

    // Player (controllable)
    player_x: f32,
    player_y: f32,
    player_size: f32,
    player_speed: f32,
};

/// Main game update function - receives memory every frame
/// This allows hot reload to work seamlessly without losing state
pub export fn game_update(
    memory: [*]u8,
    memory_size: usize,
    window_width: f32,
    window_height: f32,
) callconv(.c) void {
    // Ensure we have enough space for GameState
    if (memory_size < @sizeOf(GameState)) {
        std.debug.print("Error: Not enough memory storage!\n", .{});
        return;
    }

    // Cast memory to GameState pointer
    const state = @as(*GameState, @ptrCast(@alignCast(memory)));

    // Initialize on first run only
    if (!state.is_initialized) {
        state.* = .{
            .is_initialized = true,
            .reload_count = 0,
            .counter = 0,

            // Red rectangle
            .rect_x = 0.0,
            .rect_y = 200.0,
            .rect_width = 50.0,
            .rect_height = 50.0,
            .direction = 2.0,

            // Player
            .player_x = window_width / 2.0,
            .player_y = window_height / 2.0,
            .player_size = 40.0,
            .player_speed = 3.0,
        };

        std.debug.print("=== GAME INITIALIZED ===\n", .{});
        std.debug.print("Window: {d:.0}x{d:.0}\n", .{ window_width, window_height });
        std.debug.print("Player at: ({d:.1}, {d:.1})\n", .{ state.player_x, state.player_y });
        std.debug.print("Red rect at: ({d:.1}, {d:.1})\n", .{ state.rect_x, state.rect_y });

        return; // Skip first frame update
    }

    // ========================================
    // GAME LOGIC
    // ========================================

    state.counter += 1;

    // Update bouncing rectangle position
    state.rect_x += state.direction;

    // Bounce at screen edges
    if (state.rect_x <= 0 or state.rect_x + state.rect_width >= window_width) {
        state.direction *= -1;
    }

    // Player movement with WASD
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

    // Boundary clamping (keep player on screen)
    state.player_x = @max(0, @min(window_width - state.player_size, state.player_x));
    state.player_y = @max(0, @min(window_height - state.player_size, state.player_y));

    // Debug output every 60 frames (1 second at 60fps)
    if (state.counter % 60 == 0) {
        std.debug.print("Frame: {}, RedRect_X: {d:.1}, Player: ({d:.1}, {d:.1}), Reloads: {}\n", .{
            state.counter,
            state.rect_x,
            state.player_x,
            state.player_y,
            state.reload_count,
        });
    }

    // ========================================
    // RENDERING
    // ========================================

    // Draw red bouncing rectangle
    c.drawRectangle(
        state.rect_x,
        state.rect_y,
        state.rect_width,
        state.rect_height,
        c.RED,
    );

    // Draw player (purple square)
    c.drawRectangle(
        state.player_x,
        state.player_y,
        state.player_size,
        state.player_size,
        c.PURPLE,
    );

    // Draw FPS counter
    c.drawText("FPS: 60", 10.0, 10.0, 20.0, c.YELLOW);

    // Draw reload count (helps verify hot reload is working)
    if (state.reload_count > 0) {
        var buffer: [64]u8 = undefined;
        const text = std.fmt.bufPrintZ(&buffer, "Hot Reloads: {}", .{state.reload_count}) catch "Error";
        //                    ^^^^^^^ MUDANÇA AQUI: bufPrint → bufPrintZ
        c.drawText(text.ptr, 10.0, 40.0, 20.0, c.GREEN);
    }
}

/// Called when the game code is hot-reloaded
/// This allows you to track reloads and perform any necessary adjustments
pub export fn game_on_reload(
    memory: [*]u8,
    memory_size: usize,
) callconv(.c) void {
    if (memory_size < @sizeOf(GameState)) return;

    const state = @as(*GameState, @ptrCast(@alignCast(memory)));
    state.reload_count += 1;

    std.debug.print("\n🔥 HOT RELOAD #{} 🔥\n", .{state.reload_count});
    std.debug.print("State preserved! Frame: {}, Player: ({d:.1}, {d:.1})\n", .{
        state.counter,
        state.player_x,
        state.player_y,
    });
    std.debug.print("Red rect at: {d:.1}\n\n", .{state.rect_x});
}
