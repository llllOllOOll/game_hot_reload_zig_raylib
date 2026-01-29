/// Color representation independent from Raylib
pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

/// Common colors
pub const BLACK = Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
pub const WHITE = Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
pub const RED = Color{ .r = 255, .g = 0, .b = 0, .a = 255 };
pub const GREEN = Color{ .r = 0, .g = 255, .b = 0, .a = 255 };
pub const BLUE = Color{ .r = 0, .g = 0, .b = 255, .a = 255 };
pub const YELLOW = Color{ .r = 255, .g = 255, .b = 0, .a = 255 };
pub const PURPLE = Color{ .r = 200, .g = 122, .b = 255, .a = 255 };

/// Render commands written by game code
pub const RenderCommand = union(enum) {
    clear_background: struct {
        color: Color,
    },

    draw_rectangle: struct {
        x: f32,
        y: f32,
        width: f32,
        height: f32,
        color: Color,
    },

    draw_text: struct {
        text: [256]u8,
        text_len: usize,
        x: f32,
        y: f32,
        size: f32,
        color: Color,
    },
};
