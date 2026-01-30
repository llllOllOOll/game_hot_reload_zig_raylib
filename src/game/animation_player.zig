const std = @import("std");
const Animation = @import("animation.zig");

const AnimationPlayer = @This();

const MAX_ANIMATIONS = 8;

animations: [MAX_ANIMATIONS]Animation,
animation_names: [MAX_ANIMATIONS][]const u8,
animation_count: usize,
current_index: ?usize,

pub fn init() AnimationPlayer {
    return .{
        .animations = undefined,
        .animation_names = undefined,
        .animation_count = 0,
        .current_index = null,
    };
}

pub fn addAnimation(self: *AnimationPlayer, name: []const u8, animation: Animation) !void {
    if (self.animation_count >= MAX_ANIMATIONS) {
        return error.TooManyAnimations;
    }

    self.animation_names[self.animation_count] = name;
    self.animations[self.animation_count] = animation;
    self.animation_count += 1;
}

pub fn play(self: *AnimationPlayer, name: []const u8) !void {
    for (self.animation_names[0..self.animation_count], 0..) |anim_name, i| {
        if (std.mem.eql(u8, anim_name, name)) {
            // Reset animation if switching to a different one
            if (self.current_index) |current| {
                if (current != i) {
                    self.animations[i].reset();
                }
            }
            self.current_index = i;
            return;
        }
    }
    return error.AnimationNotFound;
}

pub fn update(self: *AnimationPlayer, dt: f32) void {
    if (self.current_index) |index| {
        self.animations[index].update(dt);
    }
}

pub fn getCurrentAnimation(self: *AnimationPlayer) ?*Animation {
    if (self.current_index) |index| {
        return &self.animations[index];
    }
    return null;
}

pub fn isPlaying(self: *AnimationPlayer, name: []const u8) bool {
    if (self.current_index) |index| {
        return std.mem.eql(u8, self.animation_names[index], name);
    }
    return false;
}

pub fn isFinished(self: *AnimationPlayer) bool {
    if (self.getCurrentAnimation()) |anim| {
        return anim.finished;
    }
    return false;
}
