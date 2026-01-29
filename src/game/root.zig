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

// ============================================================
// CommandBuffer
// ============================================================

// pub const CommandBuffer = opaque {
//     extern fn pushClearBackground(self: *CommandBuffer, color: Color) void;
//     extern fn pushDrawRectangle(
//         self: *CommandBuffer,
//         x: f32,
//         y: f32,
//         width: f32,
//         height: f32,
//         color: Color,
//     ) void;
// };

pub const CommandBuffer = opaque {
    extern fn pushClearBackground(
        self: *CommandBuffer,
        r: u8,
        g: u8,
        b: u8,
        a: u8,
    ) void;

    extern fn pushDrawRectangle(
        self: *CommandBuffer,
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        r: u8,
        g: u8,
        b: u8,
        a: u8,
    ) void;
};

// ============================================================
// Exports
// ============================================================

pub export fn game_update(
    memory: [*]u8,
    memory_size: usize,
    window_width: f32,
    window_height: f32,
    command_buffer: *CommandBuffer,
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

    // AGORA VAMOS CHAMAR OS MÉTODOS
    // command_buffer.pushClearBackground(BLACK);
    // command_buffer.pushDrawRectangle(100, 100, 50, 50, RED);

    command_buffer.pushClearBackground(
        BLACK.r,
        BLACK.g,
        BLACK.b,
        BLACK.a,
    );

    command_buffer.pushDrawRectangle(
        100,
        100,
        50,
        50,
        RED.r,
        RED.g,
        RED.b,
        RED.a,
    );
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

// const std = @import("std");
//
// //
// // ============================================================
// // Shared ABI-safe types (must match platform exactly)
// // ============================================================
// //
//
// // Plain old data — safe across DLL boundary
// pub const Color = extern struct {
//     r: u8,
//     g: u8,
//     b: u8,
//     a: u8,
// };
//
// // Common colors
// pub const BLACK = Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
// pub const WHITE = Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
// pub const RED = Color{ .r = 255, .g = 0, .b = 0, .a = 255 };
// pub const GREEN = Color{ .r = 0, .g = 255, .b = 0, .a = 255 };
// pub const BLUE = Color{ .r = 0, .g = 0, .b = 255, .a = 255 };
// pub const YELLOW = Color{ .r = 255, .g = 255, .b = 0, .a = 255 };
// pub const PURPLE = Color{ .r = 200, .g = 122, .b = 255, .a = 255 };
//
// //
// // ============================================================
// // Opaque CommandBuffer interface (implemented by platform)
// // ============================================================
// //
//
// pub const CommandBuffer = opaque {
//     extern fn pushClearBackground(self: *CommandBuffer, color: Color) void;
//     extern fn pushDrawRectangle(
//         self: *CommandBuffer,
//         x: f32,
//         y: f32,
//         width: f32,
//         height: f32,
//         color: Color,
//     ) void;
//
//     extern fn pushDrawText(
//         self: *CommandBuffer,
//         text_ptr: [*]const u8,
//         text_len: usize,
//         x: f32,
//         y: f32,
//         size: f32,
//         color: Color,
//     ) void;
// };
//
// //
// // ============================================================
// // Input (temporary direct extern — later becomes InputBuffer)
// // ============================================================
// //
//
// extern fn isKeyDown(key: c_int) bool;
//
// const KEY_W: c_int = 87;
// const KEY_A: c_int = 65;
// const KEY_S: c_int = 83;
// const KEY_D: c_int = 68;
//
// //
// // ============================================================
// // Persistent game state (lives in permanent memory)
// // ============================================================
// //
//
// pub const GameState = struct {
//     initialized: bool,
//     reload_count: u32,
//     frame_counter: u64,
//
//     // Moving rectangle
//     rect_x: f32,
//     rect_y: f32,
//     rect_w: f32,
//     rect_h: f32,
//     rect_dir: f32,
//
//     // Player
//     player_x: f32,
//     player_y: f32,
//     player_size: f32,
//     player_speed: f32,
// };
//
// //
// // ============================================================
// // Game update (called every frame by platform)
// // ============================================================
// //
//
// pub export fn game_update(
//     memory: [*]u8,
//     memory_size: usize,
//     window_width: f32,
//     window_height: f32,
//     command_buffer: *CommandBuffer,
// ) callconv(.c) void {
//     if (memory_size < @sizeOf(GameState)) return;
//
//     const state = @as(*GameState, @ptrCast(@alignCast(memory)));
//
//     // ------------------------------------------------------------
//     // First-time initialization
//     // ------------------------------------------------------------
//     if (!state.initialized) {
//         state.* = .{
//             .initialized = true,
//             .reload_count = 0,
//             .frame_counter = 0,
//
//             .rect_x = 0,
//             .rect_y = window_height * 0.4,
//             .rect_w = 50,
//             .rect_h = 50,
//             .rect_dir = 2.5,
//
//             .player_x = window_width * 0.5,
//             .player_y = window_height * 0.5,
//             .player_size = 40,
//             .player_speed = 3.0,
//         };
//
//         std.debug.print("🎮 Game initialized ({d:.0}x{d:.0})\n", .{
//             window_width,
//             window_height,
//         });
//         return;
//     }
//
//     state.frame_counter += 1;
//
//     // ------------------------------------------------------------
//     // Update logic
//     // ------------------------------------------------------------
//
//     // Bouncing rectangle
//     state.rect_x += state.rect_dir;
//     if (state.rect_x <= 0 or state.rect_x + state.rect_w >= window_width) {
//         state.rect_dir *= -1;
//     }
//
//     // Player movement
//     if (isKeyDown(KEY_W)) state.player_y -= state.player_speed;
//     if (isKeyDown(KEY_S)) state.player_y += state.player_speed;
//     if (isKeyDown(KEY_A)) state.player_x -= state.player_speed;
//     if (isKeyDown(KEY_D)) state.player_x += state.player_speed;
//
//     // Clamp player
//     state.player_x = @max(0, @min(window_width - state.player_size, state.player_x));
//     state.player_y = @max(0, @min(window_height - state.player_size, state.player_y));
//
//     // ------------------------------------------------------------
//     // Render commands (NO Raylib here)
//     // ------------------------------------------------------------
//
//     command_buffer.pushClearBackground(BLACK);
//
//     // Moving rectangle
//     command_buffer.pushDrawRectangle(
//         state.rect_x,
//         state.rect_y,
//         state.rect_w,
//         state.rect_h,
//         RED,
//     );
//
//     // Player
//     command_buffer.pushDrawRectangle(
//         state.player_x,
//         state.player_y,
//         state.player_size,
//         state.player_size,
//         PURPLE,
//     );
//
//     // Debug text
//     const title = "Hot Reload + Command Buffer";
//     command_buffer.pushDrawText(title.ptr, title.len, 10, 10, 20, WHITE);
//
//     var buffer: [64]u8 = undefined;
//     const txt = std.fmt.bufPrint(
//         &buffer,
//         "Frame: {} | Reloads: {}",
//         .{ state.frame_counter, state.reload_count },
//     ) catch return;
//
//     command_buffer.pushDrawText(txt.ptr, txt.len, 10, 40, 18, YELLOW);
// }
//
// //
// // ============================================================
// // Hot reload notification
// // ============================================================
// //
//
// pub export fn game_on_reload(
//     memory: [*]u8,
//     memory_size: usize,
// ) callconv(.c) void {
//     if (memory_size < @sizeOf(GameState)) return;
//
//     const state = @as(*GameState, @ptrCast(@alignCast(memory)));
//     state.reload_count += 1;
//
//     std.debug.print(
//         "🔥 Hot reload #{} | frame {}\n",
//         .{ state.reload_count, state.frame_counter },
//     );
// }
