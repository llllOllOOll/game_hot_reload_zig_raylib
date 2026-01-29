const std = @import("std");
const Platform = @import("platform").Platform;
const c = Platform.c;

// Tipo das funções exportadas pelo game code
const GameUpdateFn = *const fn (
    memory_ptr: [*]u8,
    memory_size: usize,
    window_width: f32,
    window_height: f32,
) callconv(.c) void;

const GameOnReloadFn = *const fn (
    memory_ptr: [*]u8,
    memory_size: usize,
) callconv(.c) void;

const GameCode = struct {
    lib: std.DynLib,
    update_fn: GameUpdateFn,
    on_reload_fn: ?GameOnReloadFn,
    last_mod_time: std.Io.Timestamp,

    pub fn load(path: []const u8) !GameCode {
        var threaded = std.Io.Threaded.init_single_threaded;
        const io = threaded.io();

        var lib = try std.DynLib.open(path);
        errdefer lib.close();

        const update_fn = lib.lookup(GameUpdateFn, "game_update") orelse
            return error.SymbolNotFound;
        const on_reload_fn = lib.lookup(GameOnReloadFn, "game_on_reload");

        const file = try std.Io.Dir.cwd().openFile(io, path, .{});
        defer file.close(io);
        const stat = try file.stat(io);

        return .{
            .lib = lib,
            .update_fn = update_fn,
            .on_reload_fn = on_reload_fn,
            .last_mod_time = stat.mtime,
        };
    }

    pub fn unload(self: *GameCode) void {
        self.lib.close();
    }
};

fn hotReloadIfNeeded(
    game_code: *GameCode,
    path: []const u8,
    permanent_memory: [*]u8,
    permanent_size: usize,
) void {
    var threaded = std.Io.Threaded.init_single_threaded;
    const io = threaded.io();

    const file = std.Io.Dir.cwd().openFile(io, path, .{}) catch return;
    defer file.close(io);

    const stat = file.stat(io) catch return;

    if (stat.mtime.nanoseconds != game_code.last_mod_time.nanoseconds) {
        std.debug.print("\n🔥 Hot reload detected!\n", .{});

        const new_game_code = GameCode.load(path) catch |err| {
            std.debug.print("Hot reload failed: {}, keeping old code\n\n", .{err});
            return;
        };

        game_code.unload();
        game_code.* = new_game_code;

        // Notify game code about reload
        if (game_code.on_reload_fn) |on_reload| {
            on_reload(permanent_memory, permanent_size);
        }

        std.debug.print("✓ Reloaded successfully!\n\n", .{});
    }
}

pub fn main() !void {
    std.debug.print("=== Game Engine with Hot Reload ===\n", .{});
    std.debug.print("Loading game code dynamically...\n", .{});
    std.debug.print("---\n", .{});

    // Initialize platform
    var platform = try Platform.init(.{
        .width = 1280,
        .height = 720,
        .title = "My Game - Hot Reload",
        .resizable = true,
    });
    defer platform.deinit();
    platform.setTargetFPS(60);

    // Permanent game memory
    const GAME_MEMORY_SIZE = 16 * 1024;

    // var game_memory: [GAME_MEMORY_SIZE]u8 = undefined;
    // @memset(&game_memory, 0);

    var game_memory: [GAME_MEMORY_SIZE]u8 align(8) = undefined; // ← ADICIONAR align(8)
    @memset(&game_memory, 0);

    // Load game code dynamically
    const so_path = "zig-out/lib/libgame.so";
    var game_code = try GameCode.load(so_path);
    defer game_code.unload();

    std.debug.print("✓ Loaded: {s}\n", .{so_path});
    std.debug.print("✓ Permanent storage: {} bytes\n", .{game_memory.len});
    std.debug.print("✓ Window: {}x{}\n", .{ platform.config.width, platform.config.height });
    std.debug.print("---\n", .{});
    std.debug.print("Press WASD to move, modify src/game/root.zig and recompile for hot reload!\n\n", .{});

    // Main game loop
    while (!platform.shouldClose()) {
        // Check for hot reload every frame
        hotReloadIfNeeded(&game_code, so_path, &game_memory, game_memory.len);

        platform.beginFrame();
        platform.pollEvents();
        c.clearBackground(c.BLACK);

        // Call dynamically loaded game update
        game_code.update_fn(
            &game_memory,
            game_memory.len,
            @as(f32, @floatFromInt(platform.config.width)),
            @as(f32, @floatFromInt(platform.config.height)),
        );

        platform.endFrame();
    }

    std.debug.print("\n=== Game closed ===\n", .{});
}
