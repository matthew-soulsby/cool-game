const std = @import("std");
const rl = @cImport(@cInclude("raylib.h"));
const Screen = @import("screens/_union.zig");
const TitleScreen = @import("screens/title.zig");
const GameScreen = @import("screens/game.zig");

pub fn main() !void {
    const screen_width = 800;
    const screen_height = 450;

    // Init allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            @panic("TEST FAIL");
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
        .game = GameScreen{},
    };
    try curr_screen.game.init(&allocator);
    defer curr_screen.game.deinit();

    // Main game loop
    while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
        // Process input
        switch (curr_screen) {
            .title => |*title_screen| title_screen.*.handleInput(),
            .game => |*game_screen| {
                game_screen.*.handleInput();
                game_screen.*.updatePositions();
            },
        }
        // Draw
        //----------------------------------------------------------------------------------
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.DARKGRAY);

        switch (curr_screen) {
            .title => |*title_screen| title_screen.*.draw(&@as(u16, screen_width)),
            .game => |*game_screen| game_screen.*.draw(),
        }

        // Debug
        rl.DrawFPS(0, 0);
        //----------------------------------------------------------------------------------
    }
}
