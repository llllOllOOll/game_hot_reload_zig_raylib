const std = @import("std");
const Platform = @import("platform").Platform;
const builtin = @import("builtin");

const dl = @cImport({
    @cInclude("dlfcn.h");
});

const GameUpdateFn = *const fn (
    memory_ptr: [*]u8,
    memory_size: usize,
    window_width: f32,
    window_height: f32,
    renderer: *Platform.Renderer,
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
        const file1 = try std.Io.Dir.cwd().openFile(io, path, .{});
        defer file1.close(io);

        var path_buf: [std.fs.max_path_bytes]u8 = undefined;
        const path_z = try std.fmt.bufPrintZ(&path_buf, "{s}", .{path});

        const handle = dl.dlopen(path_z.ptr, dl.RTLD_LAZY | dl.RTLD_LOCAL);
        if (handle == null) {
            const err_msg = dl.dlerror();
            if (err_msg != null) {
                std.debug.print("❌ dlopen error: {s}\n", .{err_msg});
            }
            return error.DynamicLibraryLoadFailed; // <-- mudou aqui
        }

        var lib = std.DynLib{ .inner = .{ .handle = handle.? } };
        errdefer lib.close();

        const update_fn = lib.lookup(GameUpdateFn, "game_update") orelse {
            std.debug.print("❌ Symbol 'game_update' not found in {s}\n", .{path}); // <-- adicionou
            return error.SymbolNotFound;
        };

        const on_reload_fn = lib.lookup(GameOnReloadFn, "game_on_reload");

        const file = try std.Io.Dir.cwd().openFile(io, path, .{});
        defer file.close(io);
        const stat = try file.stat(io);

        std.debug.print("[HOT-RELOAD-DEBUG] Initial library loaded, storing timestamp: {}\n", .{stat.mtime.nanoseconds});

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

    const file = std.Io.Dir.cwd().openFile(io, path, .{}) catch {
        std.debug.print("[HOT-RELOAD-DEBUG] Failed to open file: {s}\n", .{path});
        return;
    };
    defer file.close(io);

    const stat = file.stat(io) catch {
        std.debug.print("[HOT-RELOAD-DEBUG] Failed to stat file: {s}\n", .{path});
        return;
    };

    const timestamps_differ = stat.mtime.nanoseconds != game_code.last_mod_time.nanoseconds;
    if (timestamps_differ) {
        std.debug.print("\n🔥 Hot reload detected!\n", .{});

        game_code.unload();
        const new_game_code = GameCode.load(path) catch |err| {
            std.debug.print("[HOT-RELOAD-DEBUG] Library load failed: {}\n", .{err});
            return;
        };
        std.debug.print("[HOT-RELOAD-DEBUG] New library loaded successfully\n", .{});

        game_code.* = new_game_code;

        // Notify game code about reload
        if (game_code.on_reload_fn) |on_reload| {
            on_reload(permanent_memory, permanent_size);
            std.debug.print("[HOT-RELOAD-DEBUG] on_reload callback completed\n", .{});
        } else {
            std.debug.print("[HOT-RELOAD-DEBUG] No on_reload function found\n", .{});
        }
    }
}

pub fn main() !void {
    std.debug.print("=== Game Engine with Hot Reload + Command Buffer ===\n", .{});
    std.debug.print("Loading game code dynamically...\n", .{});
    std.debug.print("---\n", .{});

    // Initialize allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize platform with allocator
    var platform = try Platform.init(allocator, .{
        .width = 1280,
        .height = 720,
        .title = "My Game - Hot Reload + Command Buffer",
        .resizable = true,
    });
    defer platform.deinit();

    platform.setTargetFPS(60);

    // Permanent game memory
    const GAME_MEMORY_SIZE = 16 * 1024;
    var game_memory: [GAME_MEMORY_SIZE]u8 align(8) = undefined;
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
    var frame_counter: u64 = 0;
    while (!platform.shouldClose()) {
        frame_counter += 1;
        if (frame_counter % 60 == 0) { // Print once per second at 60 FPS
            // std.debug.print("[HOT-RELOAD-DEBUG] Frame {} - Checking hot reload\n", .{frame_counter});
        }

        // Check for hot reload every frame
        hotReloadIfNeeded(&game_code, so_path, &game_memory, game_memory.len);

        platform.beginFrame();
        platform.pollEvents();

        // Call dynamically loaded game update
        game_code.update_fn(
            &game_memory,
            game_memory.len,
            @as(f32, @floatFromInt(platform.config.width)),
            @as(f32, @floatFromInt(platform.config.height)),
            platform.getRenderer(), // <-- e aqui
        );

        platform.endFrame();
    }

    std.debug.print("\n=== Game closed ===\n", .{});
}
