pub const Platform = @This();

pub const Window = @import("window.zig").Window;
pub const c = @import("window.zig").c;

pub const Config = struct {
    width: i32,
    height: i32,
    title: [:0]const u8,
    resizable: bool,
};

window: Window,
config: Config,

pub fn init(config: Config) !Platform {
    const window = try Window.init(config.title, config.width, config.height, config.resizable);
    return Platform{
        .window = window,
        .config = config,
    };
}

pub fn deinit(self: *Platform) void {
    self.window.deinit();
}

// Window delegation methods
pub fn setTargetFPS(self: *Platform, fps: i32) void {
    self.window.setTargetFPS(fps);
}

pub fn shouldClose(self: *const Platform) bool {
    return self.window.shouldClose();
}
// Platform frame methods
pub fn beginFrame(self: *Platform) void {
    _ = self;
    c.beginDrawing();
    // c.clearBackground(c.GREEN); // <-- ADD THIS LINE ONLY
}
pub fn endFrame(self: *Platform) void {
    _ = self;
    c.endDrawing();
}
pub fn pollEvents(self: *Platform) void {
    _ = self;
    // Raylib handles events automatically
    // Placeholder for future input systems
}
