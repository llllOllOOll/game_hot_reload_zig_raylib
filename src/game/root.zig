const std = @import("std");
const Animation = @import("animation.zig");
const AnimationPlayer = @import("animation_player.zig");

// ============================================================
// Structs basics
// ============================================================
pub const Texture2D = opaque {};
pub const Rectangle = @import("animation.zig").Rectangle;
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
pub const Vec2 = @import("animation.zig").Vec2;

pub const GameState = struct {
    initialized: bool,
    frame_counter: u64,
    player_pos: Vec2,
    velocity_y: f32,
    velocity_x: f32,
    coyote_timer: f32,
    is_jumping: bool,
    anim_player: AnimationPlayer,
    walk_texture: *Texture2D,
    walk_left_texture: *Texture2D,
    walk_right_texture: *Texture2D,
    facing_right: bool, // Track direction
};

pub const Renderer = opaque {
    extern fn clear(self: *Renderer, color: Color) void;
    extern fn rect(self: *Renderer, pos: Vec2, size: Vec2, color: Color) void;
    extern fn isKeyPressed(self: *Renderer, key: i32) bool;
    extern fn isKeyDown(self: *Renderer, key: i32) bool;
    extern fn loadTexture(self: *Renderer, path: [*]const u8) *Texture2D;
    extern fn drawTexture(self: *Renderer, texture: *Texture2D, src_rect: Rectangle, dest_rect: Rectangle, origin: Vec2, rotation: f32, tint: Color) void;
};

pub const Vec4 = extern struct { x: f32, y: f32, z: f32, w: f32 };

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
        // Load texture for animation
        const walk_left_texture = renderer.loadTexture("assets/walk/walk_Left_Up.png");
        const walk_right_texture = renderer.loadTexture("assets/walk/walk_Right_Up.png");

        state.* = .{
            .initialized = true,
            .frame_counter = 0,
            .player_pos = .{ .x = 200, .y = 550 },
            .velocity_y = 0,
            .velocity_x = 0,
            .coyote_timer = 0,
            .is_jumping = false,
            .anim_player = AnimationPlayer.init(),
            .walk_texture = undefined, // Will be set below
            .walk_left_texture = walk_left_texture,
            .walk_right_texture = walk_right_texture,
            .facing_right = true,
        };

        const walk_left = Animation.init(walk_left_texture, 384.0, 64.0, 8, 0.1, true);
        const walk_right = Animation.init(walk_right_texture, 384.0, 64.0, 8, 0.1, true);

        state.anim_player.addAnimation("walk_left", walk_left) catch {};
        state.anim_player.addAnimation("walk_right", walk_right) catch {};

        state.anim_player.play("walk_left") catch {};

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
    if (direction < 0) {
        state.facing_right = false;
        state.anim_player.play("walk_left") catch {};
        std.debug.print("← Moving left, facing_right: {}\n", .{state.facing_right});
    } else if (direction > 0) {
        state.facing_right = true;
        state.anim_player.play("walk_right") catch {};
        std.debug.print("→ Moving right, facing_right: {}\n", .{state.facing_right});
    }

    state.player_pos.x += state.velocity_x * dt;

    // ============================================================
    // Vertical Movement (gravity + jump)
    // ============================================================

    // Apply gravity
    state.velocity_y += gravity * dt;
    state.player_pos.y += state.velocity_y * dt;

    // Ground collision
    const on_ground = state.player_pos.y + 50.0 >= 670.0;

    if (on_ground) {
        state.player_pos.y = 670.0 - 50.0;
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

    // Atualizar animação
    state.anim_player.update(dt);

    // Desenhar animação ao invés do retângulo
    if (state.anim_player.getCurrentAnimation()) |anim| {
        const source = anim.getSourceRect(!state.facing_right); // flip_x based on direction
        const dest = anim.getDestRect(state.player_pos, 3.0); // scale = 1.0

        const origin = Vec2{ .x = 24, .y = 64 }; // Metade da largura (48/2), altura total (64)
        const tint = Color{ .r = 255, .g = 255, .b = 255, .a = 255 };

        // Draw animation with appropriate texture
        const current_texture = if (state.facing_right) state.walk_right_texture else state.walk_left_texture;
        renderer.drawTexture(current_texture, source, dest, origin, 0.0, tint);
    } else {
        std.debug.print("No current animation!\n", .{});
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

    // Draw ground
    renderer.rect(.{ .x = 0, .y = 685.0 }, .{ .x = 1280, .y = 50 }, WHITE);

    // Debug frame counter
    if (state.frame_counter % 60 == 0) {
        // std.debug.print("✅ Frame from Game: {}\n", .{state.frame_counter});
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
