const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ========================================
    // DEPENDÊNCIA ZRAYLIB
    // ========================================
    const zraylib_dep = b.dependency("zraylib", .{
        .target = target,
        .optimize = optimize,
    });
    const zraylib = zraylib_dep.module("zraylib");

    // ========================================
    // MÓDULO PLATFORM
    // ========================================
    const platform = b.addModule("platform", .{
        .root_source_file = b.path("src/platform/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "zraylib", .module = zraylib },
        },
    });

    // ========================================
    // GAME LIBRARY (HOT RELOADABLE)
    // ========================================
    const game_lib = b.addLibrary(.{
        .name = "game",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/game/root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true, // ✅ ADICIONAR AQUI
        }),
        .linkage = .dynamic,
    });

    // Adicionar imports no game_lib
    game_lib.root_module.addImport("zraylib", zraylib);
    game_lib.root_module.addImport("platform", platform);

    // ✅ IMPORTANTE: Instalar em lib/ para hot reload encontrar
    b.installArtifact(game_lib);

    // ========================================
    // EXECUTÁVEL PRINCIPAL (ENGINE)
    // ========================================
    const exe = b.addExecutable(.{
        .name = "zig_modules",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "platform", .module = platform },
            },
        }),
    });

    // ✅ IMPORTANTE: Linkar com libdl para dlopen/dlsym (hot reload)
    if (target.result.os.tag == .linux) {
        exe.root_module.linkSystemLibrary("dl", .{});
    }

    b.installArtifact(exe);

    // ========================================
    // RUN STEP
    // ========================================
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // ========================================
    // WATCH STEP (OPCIONAL - Para desenvolvimento)
    // ========================================
    const watch_step = b.step("watch", "Rebuild game.so on changes");
    const watch_cmd = b.addSystemCommand(&.{ "sh", "-c", "while true; do " ++
        "inotifywait -e modify src/game/*.zig && " ++
        "zig build; " ++
        "done" });
    watch_step.dependOn(&watch_cmd.step);
}
