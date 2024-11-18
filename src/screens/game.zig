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

screen_width: *const u16,
screen_height: *const u16,
allocator: *const Allocator = undefined,
ball: Ball = undefined,
player_list: ArrayList(Player) = undefined,
paused: bool = undefined,
pause_time: f64 = undefined,

pub fn init(self: *GameScreen, allocator: *const Allocator) !void {
    self.allocator = allocator;
    self.player_list = ArrayList(Player).init(allocator.*);
    errdefer self.player_list.deinit();

    const full_screen_x: f32 = @floatFromInt(self.screen_width.*);
    const half_screen_x: f32 = @floatFromInt(self.screen_width.* / 2);
    const half_screen_y: f32 = @floatFromInt(self.screen_height.* / 2);
    const half_ball: f32 = (BallSize.x / 2);
    const half_player_y: f32 = (PlayerSize.y / 2);

    self.ball = Ball{
        .position = rl.Vector2{
            .x = half_screen_x - half_ball,
            .y = 0,
        },
        .velocity = rl.Vector2{
            .x = BASE_VELOCITY,
            .y = BASE_VELOCITY,
        },
        .size = BallSize,
    };

    try self.player_list.append(Player{
        .position = rl.Vector2{
            .x = 0,
            .y = half_screen_y - half_player_y,
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
            .x = full_screen_x - PlayerSize.x,
            .y = half_screen_y - half_player_y,
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

    self.pauseGame();
}

fn pauseGame(self: *GameScreen) void {
    self.paused = true;
    self.pause_time = rl.GetTime();
}

pub fn handleInput(self: *GameScreen) void {
    for (self.player_list.items) |*curr_player| {
        const up_velocity: f32 = @floatFromInt(@intFromBool(curr_player.moveEvent(curr_player.up_signal)));
        const down_velocity: f32 = @floatFromInt(@intFromBool(curr_player.moveEvent(curr_player.down_signal)));

        curr_player.velocity.y = (down_velocity - up_velocity) * BASE_VELOCITY;
    }
}

pub fn updatePositions(self: *GameScreen) void {
    if (self.paused) {
        if (3 > rl.GetTime() - self.pause_time) {
            return;
        }
        self.paused = false;
    }

    // Move players
    for (self.player_list.items) |*curr_player| {
        curr_player.position.x += curr_player.velocity.x;
        curr_player.position.y += curr_player.velocity.y;
    }

    // Move ball
    self.ball.position.x += self.ball.velocity.x;
    self.ball.position.y += self.ball.velocity.y;
}

pub fn draw(self: *GameScreen) !void {
    if (self.paused) {
        try self.drawPause();
    }

    for (self.player_list.items) |curr_player| {
        rl.DrawRectangleV(curr_player.position, curr_player.size, rl.WHITE);
    }

    rl.DrawRectangleV(self.ball.position, self.ball.size, rl.WHITE);
}

fn drawPause(self: *GameScreen) !void {
    const TIME_SIZE = 75;
    const time_to_display: i8 = @intFromFloat(3 + self.pause_time - rl.GetTime());
    const time_str = try std.fmt.allocPrintZ(self.allocator.*, "{}", .{time_to_display + 1});
    defer self.allocator.free(time_str);

    const half_screen_x = self.screen_width.* / 2;
    const half_screen_y = self.screen_height.* / 2;

    const half_text_x = @divTrunc(rl.MeasureText(time_str.ptr, TIME_SIZE), 2);
    const half_text_y = TIME_SIZE / 2;

    rl.DrawText(time_str.ptr, half_screen_x - half_text_x, half_screen_y - half_text_y, TIME_SIZE, rl.WHITE);
}

pub fn deinit(self: *GameScreen) void {
    self.player_list.deinit();
}
