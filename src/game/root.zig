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
    velocity_x: f32,
    coyote_timer: f32,
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
            .velocity_x = 0,
            .coyote_timer = 0,
            .is_jumping = false,
        };
        std.debug.print("🎮 Inicializado! {d}x{d}\n", .{ window_width, window_height });
    }

    state.frame_counter += 1;

    renderer.clear(BLACK);

    // ============================================================
    // Physics Configuration (Godot 4.0 compatible)
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
    // FRICTION: 0.15 (15% deceleration per frame)
    //   - Smooth deceleration when no input
    //   - Higher value = faster stop (0.0-1.0 range)
    //
    // COYOTE_TIME: 0.15 seconds
    //   - Grace period to jump after leaving platform
    //   - Makes platforming feel more forgiving
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
    const friction = 0.15;
    const coyote_time = 0.15;

    const ground_y = 670.0;
    const player_width = 50.0;
    const player_height = 50.0;

    // ============================================================
    // Horizontal Movement (with friction)
    // ============================================================
    var direction: f32 = 0;
    if (renderer.isKeyDown(KEY_A)) direction -= 1.0;
    if (renderer.isKeyDown(KEY_D)) direction += 1.0;

    if (direction != 0) {
        // Moving: accelerate in direction
        state.velocity_x = direction * speed;
    } else {
        // Stopped: decelerate smoothly
        state.velocity_x *= (1.0 - friction);
    }

    state.player_pos.x += state.velocity_x * dt;

    // ============================================================
    // Vertical Movement (gravity + jump)
    // ============================================================

    // Apply gravity
    state.velocity_y += gravity * dt;
    state.player_pos.y += state.velocity_y * dt;

    // Ground collision
    const on_ground = state.player_pos.y + player_height >= ground_y;
    if (on_ground) {
        state.player_pos.y = ground_y - player_height;
        state.velocity_y = 0;
        state.is_jumping = false;
    }

    // ============================================================
    // Coyote Time (grace period for jumping)
    // ============================================================
    if (on_ground) {
        state.coyote_timer = coyote_time; // Reset timer when on ground
    } else {
        state.coyote_timer -= dt; // Decrease timer when in air
    }

    // Jump (with coyote time)
    if (renderer.isKeyPressed(KEY_SPACE) and state.coyote_timer > 0) {
        state.velocity_y = jump_velocity;
        state.is_jumping = true;
        state.coyote_timer = 0; // Consume coyote time
    }

    // ============================================================
    // Rendering
    // ============================================================

    // Draw player
    renderer.rect(state.player_pos, .{ .x = player_width, .y = player_height }, WHITE);

    // Draw ground
    renderer.rect(.{ .x = 0, .y = ground_y }, .{ .x = 800, .y = 50 }, RED);

    // Debug frame counter
    if (state.frame_counter % 60 == 0) {
        std.debug.print("✅ Frame from Game: {}\n", .{state.frame_counter});
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
