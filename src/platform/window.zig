pub const c = @import("zraylib");

pub const Vector2 = c.Vector2;
pub const Vector3 = c.Vector3;
pub const Rectangle = c.Rectangle;
pub const Texture2D = c.Texture2D;

// Core constants
pub const RAYWHITE = c.RAYWHITE;
pub const RAYBLACK = c.RAYBLACK;
pub const RED = c.RED;
pub const GREEN = c.GREEN;
pub const BLUE = c.BLUE;
pub const WHITE = c.WHITE;
pub const BLACK = c.BLACK;
pub const LIGHTGRAY = c.LIGHTGRAY;
pub const YELLOW = c.YELLOW;

// Re-export Color from Raylib
pub const Color = c.Color;

pub const Window = struct {
    width: i32,
    height: i32,
    pub fn init(title: [:0]const u8, width: i32, height: i32, is_resizable: bool) !Window {
        if (is_resizable) {
            c.SetConfigFlags(c.FLAG_WINDOW_RESIZABLE);
        }
        c.initWindow(width, height, title);
        if (!c.isWindowReady()) {
            return error.WindowCreationFailed;
        }
        return Window{
            .width = width,
            .height = height,
        };
    }
    pub fn deinit(self: *Window) void {
        _ = self;
        c.closeWindow();
    }
    pub fn shouldClose(self: *const Window) bool {
        _ = self;
        return c.windowShouldClose();
    }
    pub fn setTargetFPS(self: *const Window, fps: i32) void {
        _ = self;
        c.setTargetFPS(fps);
    }
};

// pub const c = @import("zraylib");
//
// pub const Vector2 = c.Vector2;
// pub const Vector3 = c.Vector3;
// pub const Rectangle = c.Rectangle;
// pub const Texture2D = c.Texture2D;
//
// // Core constants
// pub const RAYWHITE = c.RAYWHITE;
// pub const RAYBLACK = c.RAYBLACK;
// pub const RED = c.RED;
// pub const GREEN = c.GREEN;
// pub const BLUE = c.BLUE;
// pub const WHITE = c.WHITE;
// pub const BLACK = c.BLACK;
// pub const LIGHTGRAY = c.LIGHTGRAY;
// pub const YELLOW = c.YELLOW;
//
// // Re-export Color from Raylib
// pub const Color = c.Color;
//
// pub const Window = struct {
//     width: i32,
//     height: i32,
//     pub fn init(title: [:0]const u8, width: i32, height: i32, is_resizable: bool) !Window {
//         if (is_resizable) {
//             c.SetConfigFlags(c.FLAG_WINDOW_RESIZABLE);
//         }
//         c.initWindow(width, height, title);
//         if (!c.isWindowReady()) {
//             return error.WindowCreationFailed;
//         }
//         return Window{
//             .width = width,
//             .height = height,
//         };
//     }
//     pub fn deinit(self: *Window) void {
//         _ = self;
//         c.closeWindow();
//     }
//     pub fn shouldClose(self: *const Window) bool {
//         _ = self;
//         return c.windowShouldClose();
//     }
//     pub fn setTargetFPS(self: *const Window, fps: i32) void {
//         _ = self;
//         c.setTargetFPS(fps);
//     }
// };

// pub const c = @import("zraylib");
//
// pub const Vector2 = c.Vector2;
// pub const Vector3 = c.Vector3;
// pub const Rectangle = c.Rectangle;
// pub const Texture2D = c.Texture2D;
//
// // Core constants
// pub const RAYWHITE = c.RAYWHITE;
// pub const RAYBLACK = c.RAYBLACK;
// pub const RED = c.RED;
// pub const GREEN = c.GREEN;
// pub const BLUE = c.BLUE;
// pub const WHITE = c.WHITE;
// pub const BLACK = c.BLACK;
// pub const LIGHTGRAY = c.LIGHTGRAY;
// pub const YELLOW = c.YELLOW;
// const Self = @This();
//
// // Re-export Color from Raylib
// pub const Color = c.Color;
//
// pub const Window = struct {
//     width: i32,
//     height: i32,
//
//     pub fn initt() !void {}
//     pub fn deinitt() !void {}
//
//     pub fn init(title: [:0]const u8, width: i32, height: i32, is_resizable: bool) !Window {
//         if (is_resizable) {
//             c.SetConfigFlags(c.FLAG_WINDOW_RESIZABLE);
//         }
//
//         c.initWindow(width, height, title);
//
//         if (!c.isWindowReady()) {
//             return error.WindowCreationFailed;
//         }
//
//         return Window{
//             .width = width,
//             .height = height,
//         };
//     }
//
//     pub fn deinit(self: *Window) void {
//         _ = self;
//         c.closeWindow();
//     }
//
//     pub fn shouldClose(self: *Window) bool {
//         _ = self;
//         return c.windowShouldClose();
//     }
//
//     pub fn setTargetFPS(self: *Window, fps: i32) void {
//         _ = self;
//         c.setTargetFPS(fps);
//     }
// };
//
// pub const Config = struct {
//     title: [:0]const u8,
//     width: i32,
//     height: i32,
//     is_resizable: bool,
// };
//
// window: Self,
// is_running: bool = true,
//
// pub fn init(config: Config) !Self {
//     // errdefer platform.deinit();
//
//     var window = try Self.init(
//         config.title,
//         config.width,
//         config.height,
//         config.is_resizable,
//     );
//     errdefer window.deinit();
//
//     // try window.show();
//     return .{
//         .window = window,
//     };
// }
//
// pub fn deinit(self: *Self) void {
//     self.window.deinit();
//     Self.deinit();
// }
