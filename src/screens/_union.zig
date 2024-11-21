const rl = @cImport(@cInclude("raylib.h"));
const std = @import("std");

const Allocator = std.mem.Allocator;
const TitleScreen = @import("title.zig");
const GameScreen = @import("game.zig");

const ScreenType = enum {
    title,
    game,
};

const ScreenUnion = union(ScreenType) {
    title: TitleScreen,
    game: GameScreen,
};

pub const Current = struct {
    allocator: *const Allocator,
    screen_width: *const u16,
    screen_height: *const u16,
    next_screen: *bool,
    exit_screen: *bool,
    screen: *ScreenUnion,

    pub fn init(self: *Current) !void {
        const screen_ptr = try self.allocator.create(ScreenUnion);
        const next_screen_ptr = try self.allocator.create(bool);
        const exit_screen_ptr = try self.allocator.create(bool);
        const title_options = try self.allocator.alloc(TitleScreen.Option, 2);

        title_options[0] = TitleScreen.Option{
            .text = "Start",
            .flag_to_flip = next_screen_ptr,
        };
        title_options[1] = TitleScreen.Option{
            .text = "Exit",
            .flag_to_flip = exit_screen_ptr,
        };

        next_screen_ptr.* = false;
        exit_screen_ptr.* = false;

        screen_ptr.* = ScreenUnion{
            .title = TitleScreen{
                .allocator = self.allocator,
                .title = "Cool Game",
                .options = title_options,
            },
        };

        self.screen = screen_ptr;
        self.next_screen = next_screen_ptr;
        self.exit_screen = exit_screen_ptr;
    }

    pub fn deinit(self: *Current) void {
        self.cleanupScreen();
        self.allocator.destroy(self.screen);
        self.allocator.destroy(self.next_screen);
        self.allocator.destroy(self.exit_screen);
    }

    fn cleanupScreen(self: *Current) void {
        switch (self.screen.*) {
            .title => |*title_screen| {
                title_screen.deinit();
            },
            .game => |*game_screen| {
                game_screen.*.deinit();
            },
        }
    }

    pub fn nextScreen(self: *Current) !void {
        const next_screen_ptr = try self.allocator.*.create(ScreenUnion);

        next_screen_ptr.* = ScreenUnion{
            .game = GameScreen{
                .screen_width = self.screen_width,
                .screen_height = self.screen_height,
            },
        };

        try next_screen_ptr.*.game.init(self.allocator);

        self.cleanupScreen();
        self.allocator.*.destroy(self.screen);

        self.screen = next_screen_ptr;
        self.next_screen.* = false;
    }

    pub fn update(self: *Current) !void {
        if (self.next_screen.*) {
            try self.nextScreen();
        }
        switch (self.screen.*) {
            .title => |*title_screen| title_screen.*.handleInput(),
            .game => |*game_screen| {
                game_screen.*.handleInput();
                game_screen.*.handleBallCollisions();
                game_screen.*.updatePositions();
            },
        }
    }

    pub fn draw(self: *Current, screen_width: *const u16) !void {
        switch (self.screen.*) {
            .title => |*title_screen| title_screen.*.draw(screen_width),
            .game => |*game_screen| try game_screen.*.draw(),
        }
    }
};
