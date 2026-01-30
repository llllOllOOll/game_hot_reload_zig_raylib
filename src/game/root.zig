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
pub const BLUE = Color{ .r = 0, .g = 0, .b = 255, .a = 255 };

// Arrow keys
const KEY_RIGHT: i32 = 262;
const KEY_LEFT: i32 = 263;
const KEY_UP: i32 = 265;
const KEY_DOWN: i32 = 264;

// WASD keys
const KEY_W: i32 = 87;
const KEY_A: i32 = 65;
const KEY_S: i32 = 83;
const KEY_D: i32 = 68;

// Space key
const KEY_SPACE: i32 = 32;

pub const GameState = struct {
    initialized: bool,
    frame_counter: u64,
    player_pos: Vec2,
    velocity_y: f32,
    is_jumping: bool,
};

pub const Vec2 = extern struct { x: f32, y: f32 };

pub const Renderer = opaque {
    extern fn clear(self: *Renderer, color: Color) void;
    extern fn rect(self: *Renderer, pos: Vec2, size: Vec2, color: Color) void;
    extern fn isKeyPressed(self: *Renderer, key: i32) bool;
    extern fn isKeyDown(self: *Renderer, key: i32) bool;
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
    dt: f32,
) callconv(.c) void {
    if (memory_size < @sizeOf(GameState)) return;

    const state = @as(*GameState, @ptrCast(@alignCast(memory)));

    if (!state.initialized) {
        state.* = .{
            .initialized = true,
            .frame_counter = 0,
            .player_pos = .{ .x = 200, .y = 200 },
            .velocity_y = 0,
            .is_jumping = false,
        };
        std.debug.print("🎮 Inicializado! {d}x{d}\n", .{ window_width, window_height });
    }

    state.frame_counter += 1;

    renderer.clear(BLACK);

    // ============================================================
    // Physics Configuration
    // ============================================================
    //
    // SPEED: 300.0 pixels/second
    //   - Horizontal movement velocity
    //   - Applied as: position += speed * dt
    //   - Example: at 60fps (dt ≈ 0.016s), moves ~5 pixels/frame
    //
    // JUMP_VELOCITY: -400.0 pixels/second
    //   - Initial upward velocity when jumping (negative = up)
    //   - Applied instantly when space is pressed
    //   - Takes ~0.4s to reach peak height (~80 pixels up)
    //
    // GRAVITY: 980.0 pixels/second²
    //   - Constant downward acceleration (Earth-like: 9.8 m/s²)
    //   - Applied as: velocity_y += gravity * dt each frame
    //   - Pulls player down creating parabolic jump arc
    //
    // Physics Loop:
    //   1. velocity_y += gravity * dt    (apply gravity)
    //   2. position.y += velocity_y * dt (apply velocity)
    //   3. if on_ground: velocity_y = 0  (stop falling)
    //
    // Delta Time (dt):
    //   - Time elapsed since last frame (in seconds)
    //   - Ensures consistent physics at any framerate
    //   - 60fps: dt ≈ 0.016s | 30fps: dt ≈ 0.033s
    // ============================================================
    const speed = 300.0;
    const jump_velocity = -400.0;
    const gravity = 980.0;
    const ground_y = 400.0;

    if (renderer.isKeyDown(KEY_A)) {
        state.player_pos.x -= speed * dt;
    }
    if (renderer.isKeyDown(KEY_D)) {
        state.player_pos.x += speed * dt;
    }

    // Jump (only when on ground)
    if (renderer.isKeyPressed(KEY_SPACE) and !state.is_jumping) {
        state.velocity_y = jump_velocity;
        state.is_jumping = true;
    }

    // Apply gravity
    state.velocity_y += gravity * dt;
    state.player_pos.y += state.velocity_y * dt;

    // Ground collision
    if (state.player_pos.y >= ground_y) {
        state.player_pos.y = ground_y;
        state.velocity_y = 0;
        state.is_jumping = false;
    }

    // Draw player
    renderer.rect(state.player_pos, .{ .x = 100, .y = 201 }, WHITE);
    // renderer.rect(.{ .x = 0, .y = ground_y + 201 }, .{ .x = 800, .y = 50 }, BLUE);
    renderer.rect(.{ .x = 0, .y = ground_y + 201 }, .{ .x = 800, .y = 50 }, RED);
    // renderer.rect(.{ .x = 100, .y = 100 }, .{ .x = 50, .y = 50 }, RED);

    if (state.frame_counter % 60 == 0) {
        std.debug.print("✅ Frame  from Game .so Let see Luna! {}\n", .{state.frame_counter});
    }
}

pub export fn game_on_reload(
    memory: [*]u8,
    memory_size: usize,
) callconv(.c) void {
    if (memory_size < @sizeOf(GameState)) return;

    const state = @as(*GameState, @ptrCast(@alignCast(memory)));
    std.debug.print("🔥 Hot reload! Frame - Game  atual: {}\n", .{state.frame_counter});
}
