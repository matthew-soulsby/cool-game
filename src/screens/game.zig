const std = @import("std");
const rl = @cImport(@cInclude("raylib.h"));

const GameScreen = @This();
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const BASE_VELOCITY = 2.5;

const Ball = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    size: rl.Vector2,
};
pub const Player = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    size: rl.Vector2,
    up_signal: c_int,
    down_signal: c_int,
    moveEvent: *const fn (c_int) callconv(.C) bool,
};
const PlayerSize = rl.Vector2{
    .x = 20,
    .y = 60,
};
const BallSize = rl.Vector2{
    .x = 20,
    .y = 20,
};

ball: Ball = Ball{
    .position = rl.Vector2{
        .x = 100,
        .y = 100,
    },
    .velocity = rl.Vector2{
        .x = BASE_VELOCITY,
        .y = BASE_VELOCITY,
    },
    .size = BallSize,
},
player_list: ArrayList(Player) = undefined,

pub fn init(self: *GameScreen, allocator: *const Allocator) !void {
    self.player_list = ArrayList(Player).init(allocator.*);
    errdefer self.player_list.deinit();

    try self.player_list.append(Player{
        .position = rl.Vector2{
            .x = 0,
            .y = 200,
        },
        .velocity = rl.Vector2{
            .x = 0,
            .y = 0,
        },
        .size = PlayerSize,
        .up_signal = rl.KEY_W,
        .down_signal = rl.KEY_S,
        .moveEvent = rl.IsKeyDown,
    });
    try self.player_list.append(Player{
        .position = rl.Vector2{
            .x = 800 - PlayerSize.x,
            .y = 200,
        },
        .velocity = rl.Vector2{
            .x = 0,
            .y = 0,
        },
        .size = PlayerSize,
        .up_signal = rl.KEY_UP,
        .down_signal = rl.KEY_DOWN,
        .moveEvent = rl.IsKeyDown,
    });
}

pub fn handleInput(self: *GameScreen) void {
    for (self.player_list.items) |*curr_player| {
        const up_velocity: f32 = @floatFromInt(@intFromBool(curr_player.moveEvent(curr_player.up_signal)));
        const down_velocity: f32 = @floatFromInt(@intFromBool(curr_player.moveEvent(curr_player.down_signal)));

        curr_player.velocity.y = (down_velocity - up_velocity) * BASE_VELOCITY;
    }
}

pub fn updatePositions(self: *GameScreen) void {
    // Move players
    for (self.player_list.items) |*curr_player| {
        curr_player.position.x += curr_player.velocity.x;
        curr_player.position.y += curr_player.velocity.y;
    }

    // Move ball
    self.ball.position.x += self.ball.velocity.x;
    self.ball.position.y += self.ball.velocity.y;
}

pub fn draw(self: *GameScreen) void {
    for (self.player_list.items) |curr_player| {
        rl.DrawRectangleV(curr_player.position, curr_player.size, rl.WHITE);
    }

    rl.DrawRectangleV(self.ball.position, self.ball.size, rl.WHITE);
}

pub fn deinit(self: *GameScreen) void {
    self.player_list.deinit();
}
