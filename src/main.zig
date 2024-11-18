const std = @import("std");
const rl = @cImport(@cInclude("raylib.h"));
const Screen = @import("screens/_union.zig");
const TitleScreen = @import("screens/title.zig");
const GameScreen = @import("screens/game.zig");

pub fn main() !void {
    const screen_width: u16 = 800;
    const screen_height: u16 = 450;

    // Init allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            @panic("leaky leaky");
        }
    }

    rl.InitWindow(screen_width, screen_height, "cool game - very cool");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    var curr_screen = Screen.Current{
        .title = TitleScreen{
            .title = "Cool Game",
            .options = &[_]TitleScreen.Option{
                TitleScreen.Option{
                    .text = "Start",
                    .executeOnSelect = rl.ToggleBorderlessWindowed,
                },
                TitleScreen.Option{
                    .text = "Exit",
                    .executeOnSelect = rl.ToggleBorderlessWindowed,
                },
            },
        },
    };
    curr_screen = Screen.Current{
        .game = GameScreen{
            .screen_width = &screen_width,
            .screen_height = &screen_height,
        },
    };
    try curr_screen.game.init(&allocator);
    defer curr_screen.game.deinit();

    // Main game loop
    while (!rl.WindowShouldClose()) {
        // Process input
        switch (curr_screen) {
            .title => |*title_screen| title_screen.*.handleInput(),
            .game => |*game_screen| {
                game_screen.*.handleInput();
                game_screen.*.updatePositions();
            },
        }

        // Draw
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.DARKGRAY);

        switch (curr_screen) {
            .title => |*title_screen| title_screen.*.draw(&screen_width),
            .game => |*game_screen| try game_screen.*.draw(),
        }

        // Debug
        rl.DrawFPS(0, 0);
    }
}
