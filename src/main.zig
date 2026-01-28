const std = @import("std");
const Platform = @import("platform").Platform;
const c = Platform.c;
const GAME_MEMORY_SIZE = 1024;

const game = @import("game");
const game_update_fn = game.game_update;

var game_memory: [GAME_MEMORY_SIZE]u8 = undefined;
const GameUpdateFn = *const fn ([*]u8, usize, i32, i32) callconv(.c) void;
// const game_update_fn = @extern(GameUpdateFn, .{ .name = "game_update" });

pub fn main() !void {
    var platform = try Platform.init(.{
        .width = 1280,
        .height = 720,
        .title = "My Game",
        .resizable = true,
    });
    defer platform.deinit();
    platform.setTargetFPS(60);
    // Initialize game memory
    @memset(&game_memory, 0);
    while (!platform.shouldClose()) {
        platform.beginFrame();
        platform.pollEvents();

        // game_update_fn(&game_memory, game_memory.len, platform.config.width, platform.config.height);
        game_update_fn(&game_memory, game_memory.len, @as(f32, @floatFromInt(platform.config.width)), @as(f32, @floatFromInt(platform.config.height)));
        platform.endFrame();
    }
}

// const std = @import("std");
// const Platform = @import("platform").Platform;
//
// pub fn main() !void {
//     var platform = try Platform.init(.{
//         .width = 1280,
//         .height = 720,
//         .title = "My Game",
//         .resizable = true,
//     });
//     defer platform.deinit();
//
//     platform.setTargetFPS(60);
//
//     while (!platform.shouldClose()) {
//         platform.beginFrame();
//         platform.pollEvents();
//         // game.update()
//         // game.render()
//         platform.endFrame();
//     }
// }
