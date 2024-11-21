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

    pub fn reset(self: *Ball, half_screen_x: f32) void {
        self.position.x = half_screen_x - (self.size.x / 2);
        self.position.y = 1;

        self.velocity.y = BASE_VELOCITY;
    }
};
pub const Player = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    size: rl.Vector2,
    score: u8 = '0',
    score_wall_x: f32,
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
full_screen_x: f32 = undefined,
half_screen_x: f32 = undefined,
half_screen_y: f32 = undefined,
allocator: *const Allocator = undefined,
ball: Ball = undefined,
player_list: ArrayList(Player) = undefined,
paused: bool = undefined,
to_resume: bool = undefined,
resume_time: f64 = undefined,

pub fn init(self: *GameScreen, allocator: *const Allocator) !void {
    self.allocator = allocator;
    self.player_list = ArrayList(Player).init(allocator.*);
    errdefer self.player_list.deinit();

    self.full_screen_x = @floatFromInt(self.screen_width.*);
    self.half_screen_x = @floatFromInt(self.screen_width.* / 2);
    self.half_screen_y = @floatFromInt(self.screen_height.* / 2);
    const half_ball: f32 = (BallSize.x / 2);
    const half_player_y: f32 = (PlayerSize.y / 2);

    self.ball = Ball{
        .position = rl.Vector2{
            .x = self.half_screen_x - half_ball,
            .y = 1,
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
            .y = self.half_screen_y - half_player_y,
        },
        .velocity = rl.Vector2{
            .x = 0,
            .y = 0,
        },
        .size = PlayerSize,
        .score_wall_x = self.full_screen_x - BallSize.x - 1,
        .up_signal = rl.KEY_W,
        .down_signal = rl.KEY_S,
        .moveEvent = rl.IsKeyDown,
    });
    try self.player_list.append(Player{
        .position = rl.Vector2{
            .x = self.full_screen_x - PlayerSize.x,
            .y = self.half_screen_y - half_player_y,
        },
        .velocity = rl.Vector2{
            .x = 0,
            .y = 0,
        },
        .size = PlayerSize,
        .score_wall_x = 0,
        .up_signal = rl.KEY_UP,
        .down_signal = rl.KEY_DOWN,
        .moveEvent = rl.IsKeyDown,
    });

    self.pauseGame();
    self.resumeGame();
}

fn pauseGame(self: *GameScreen) void {
    self.paused = true;
}

fn resumeGame(self: *GameScreen) void {
    self.to_resume = true;
    self.resume_time = rl.GetTime();
}

pub fn handleInput(self: *GameScreen) void {
    if (rl.IsKeyPressed(rl.KEY_P)) {
        if (!self.paused) {
            self.pauseGame();
            return;
        }

        if (!self.to_resume) {
            self.resumeGame();
            return;
        }
    }

    for (self.player_list.items) |*curr_player| {
        const up_velocity: f32 = @floatFromInt(@intFromBool(curr_player.moveEvent(curr_player.up_signal)));
        const down_velocity: f32 = @floatFromInt(@intFromBool(curr_player.moveEvent(curr_player.down_signal)));

        curr_player.velocity.y = (down_velocity - up_velocity) * BASE_VELOCITY;
    }
}

pub fn updatePositions(self: *GameScreen) void {
    if (self.paused) {
        if (!self.to_resume) {
            return;
        }
        if (3 > rl.GetTime() - self.resume_time) {
            return;
        }
        self.paused = false;
        self.to_resume = false;
    }

    // Move players
    for (self.player_list.items) |*curr_player| {
        curr_player.position.x += curr_player.velocity.x;
        curr_player.position.y += curr_player.velocity.y;

        if (curr_player.position.y < 0) {
            curr_player.position.y = 0;
        }

        if (curr_player.position.y + curr_player.size.y > self.half_screen_y * 2) {
            curr_player.position.y = self.half_screen_y * 2 - curr_player.size.y;
        }
    }

    // Move ball
    self.ball.position.x += self.ball.velocity.x;
    self.ball.position.y += self.ball.velocity.y;
}

pub fn handleBallCollisions(self: *GameScreen) void {
    const vertical_wall_size = rl.Vector2{
        .x = @floatFromInt(self.screen_width.*),
        .y = 1,
    };
    const top_left = rl.Vector2{
        .x = 0,
        .y = 0,
    };
    const bottom_left = rl.Vector2{
        .x = 0,
        .y = @floatFromInt(self.screen_height.* - 1),
    };
    // Bounce off players
    for (self.player_list.items) |*curr_player| {
        // Check player's scoring wall
        if (checkBetween(curr_player.score_wall_x, curr_player.score_wall_x + 1, self.ball.position.x)) {
            self.incrementScore(curr_player);
            return;
        }

        if (checkColliding(self.ball.position, self.ball.size, curr_player.position, curr_player.size)) {
            self.ball.velocity.x *= -1;
        }
    }

    // Bounce off walls
    if (checkColliding(self.ball.position, self.ball.size, top_left, vertical_wall_size)) {
        self.ball.velocity.y *= -1;
    }

    if (checkColliding(self.ball.position, self.ball.size, bottom_left, vertical_wall_size)) {
        self.ball.velocity.y *= -1;
    }
}

fn incrementScore(self: *GameScreen, player: *Player) void {
    // Add to score
    player.score += 1;

    if (player.score > '5') {
        std.debug.print("Winner !", .{});
    }

    // Reset ball
    self.ball.reset(self.half_screen_x);

    // Pause and resume
    self.pauseGame();
    self.resumeGame();
}

fn checkBetween(start: f32, end: f32, point: f32) bool {
    return point >= start and point <= end;
}

fn checkColliding(pos_1: rl.Vector2, size_1: rl.Vector2, pos_2: rl.Vector2, size_2: rl.Vector2) bool {
    const colliding_x = checkBetween(pos_1.x, pos_1.x + size_1.x, pos_2.x) or checkBetween(pos_2.x, pos_2.x + size_2.x, pos_1.x);
    const colliding_y = checkBetween(pos_1.y, pos_1.y + size_1.y, pos_2.y) or checkBetween(pos_2.y, pos_2.y + size_2.y, pos_1.y);

    return colliding_x and colliding_y;
}

pub fn draw(self: *GameScreen) !void {
    if (self.paused) {
        try self.drawPause();
    }

    for (self.player_list.items) |curr_player| {
        // 1 if player is left, 0 if player is right - scoring
        const player_side: f32 = @floatFromInt(@intFromBool(curr_player.position.x < self.half_screen_x));
        const score_text = [_:0]u8{curr_player.score};
        const score_size: f32 = @floatFromInt(rl.MeasureText(&score_text, 30));
        const score_pos_x = self.half_screen_x - @divTrunc(score_size, 2);
        const offset_x: f32 = 100 * (0.5 - player_side);

        rl.DrawText(&score_text, @intFromFloat(score_pos_x + offset_x), 25, 30, rl.WHITE);

        rl.DrawRectangleV(curr_player.position, curr_player.size, rl.WHITE);
    }

    rl.DrawRectangleV(self.ball.position, self.ball.size, rl.WHITE);
}

fn drawPause(self: *GameScreen) !void {
    const TIME_SIZE = 75;
    const half_screen_x = self.screen_width.* / 2;
    const half_screen_y = self.screen_height.* / 2;

    if (!self.to_resume) {
        // Pause icon
        rl.DrawRectangle(half_screen_x - 15, half_screen_y - 20, 10, 40, rl.WHITE);
        rl.DrawRectangle(half_screen_x + 5, half_screen_y - 20, 10, 40, rl.WHITE);
        return;
    }

    const time_to_display: i8 = @intFromFloat(3 + self.resume_time - rl.GetTime());
    const time_str = try std.fmt.allocPrintZ(self.allocator.*, "{}", .{time_to_display + 1});
    defer self.allocator.free(time_str);

    const half_text_x = @divTrunc(rl.MeasureText(time_str.ptr, TIME_SIZE), 2);
    const half_text_y = TIME_SIZE / 2;

    rl.DrawText(time_str.ptr, half_screen_x - half_text_x, half_screen_y - half_text_y, TIME_SIZE, rl.WHITE);
}

pub fn deinit(self: *GameScreen) void {
    self.player_list.deinit();
}
