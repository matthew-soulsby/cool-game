const std = @import("std");
const rl = @cImport(@cInclude("raylib.h"));
const Screen = @import("enums/screen.zig").Screen;
const TitleScreen = @import("screens/title.zig");

pub fn main() !void {
    const screen_width = 800;
    const screen_height = 450;

    rl.InitWindow(screen_width, screen_height, "cool game - very cool");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    const curr_screen: Screen = .Title;
    var title_screen = TitleScreen{
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
    };

    // Main game loop
    while (!rl.WindowShouldClose()) { // Detect window close button or ESC key
        // Process input
        switch (curr_screen) {
            .Title => {
                if (rl.IsKeyPressed(rl.KEY_UP)) {
                    try title_screen.selectPrevOption();
                }
                if (rl.IsKeyPressed(rl.KEY_DOWN)) {
                    try title_screen.selectNextOption();
                }
                if (rl.IsKeyPressed(rl.KEY_ENTER)) {
                    title_screen.options[title_screen.selected].executeOnSelect();
                }
            },
            .Game => {},
        }

        // Draw
        //----------------------------------------------------------------------------------
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.DARKGRAY);

        try title_screen.draw(&@as(u16, screen_width));
        //----------------------------------------------------------------------------------
    }
}
