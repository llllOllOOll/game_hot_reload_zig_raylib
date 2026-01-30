const std = @import("std");

const Animation = @This();

pub const Texture2D = @import("root.zig").Texture2D;

pub const Rectangle = extern struct { x: f32, y: f32, width: f32, height: f32 };
pub const Vec2 = extern struct { x: f32, y: f32 };

texture: *Texture2D,
num_frames: i32,
frame_timer: f32,
current_frame: i32,
frame_duration: f32,
loop: bool,
finished: bool,

// Spritesheet layout
frames_per_row: i32,
frame_width: f32,
frame_height: f32,
texture_width: f32,
texture_height: f32,

pub fn init(
    texture: *Texture2D,
    texture_width: f32,
    texture_height: f32,
    num_frames: i32,
    frame_duration: f32,
    loop: bool,
) Animation {
    return .{
        .texture = texture,
        .texture_width = texture_width,
        .texture_height = texture_height,
        .num_frames = num_frames,
        .frame_timer = 0,
        .current_frame = 0,
        .frame_duration = frame_duration,
        .loop = loop,
        .finished = false,
        .frames_per_row = num_frames,
        .frame_width = texture_width / @as(f32, @floatFromInt(num_frames)),
        .frame_height = texture_height,
    };
}

pub fn reset(self: *Animation) void {
    self.current_frame = 0;
    self.frame_timer = 0;
    self.finished = false;
}

pub fn update(self: *Animation, dt: f32) void {
    if (self.finished and !self.loop) return;

    self.frame_timer += dt;
    if (self.frame_timer >= self.frame_duration) {
        self.frame_timer = 0;
        self.current_frame += 1;

        if (self.current_frame >= self.num_frames) {
            if (self.loop) {
                self.current_frame = 0;
            } else {
                self.current_frame = self.num_frames - 1;
                self.finished = true;
            }
        }
    }
}

pub fn getSourceRect(self: Animation, flip_x: bool) Rectangle {
    const frame_x = @as(f32, @floatFromInt(@mod(self.current_frame, self.frames_per_row)));
    const frame_y = @as(f32, @floatFromInt(@divTrunc(self.current_frame, self.frames_per_row)));

    return .{
        .x = frame_x * self.frame_width,
        .y = frame_y * self.frame_height,
        .width = if (flip_x) -self.frame_width else self.frame_width,
        .height = self.frame_height,
    };
}

pub fn getDestRect(self: Animation, position: Vec2, scale: f32) Rectangle {
    return .{
        .x = position.x,
        .y = position.y,
        .width = self.frame_width * scale,
        .height = self.frame_height * scale,
    };
}
