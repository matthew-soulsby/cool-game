const std = @import("std");
const rl = @cImport(@cInclude("raylib.h"));
const Screen = @import("screens/_union.zig");
const TitleScreen = @import("screens/title.zig");
const GameScreen = @import("screens/game.zig");

const GlobalState = struct {
    screen_width: u16,
    screen_height: u16,
};

pub fn main() !void {
    const global_state = GlobalState{
        .screen_width = 800,
        .screen_height = 450,
    };

    // Init allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            @panic("leaky leaky");
        }
    }

    rl.InitWindow(
        global_state.screen_width,
        global_state.screen_height,
        "cool game - very cool",
    );
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    var curr_screen = Screen.Current{
        .allocator = &allocator,
        .screen = undefined,
        .next_screen = undefined,
        .exit_screen = undefined,
        .screen_width = &global_state.screen_width,
        .screen_height = &global_state.screen_height,
    };
    try curr_screen.init();
    defer curr_screen.deinit();

    // Main game loop
    while (!rl.WindowShouldClose() and !curr_screen.exit_screen.*) {
        // Process input
        try curr_screen.update();

        // Draw
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.DARKGRAY);

        try curr_screen.draw(&global_state.screen_width);

        // Debug
        rl.DrawFPS(0, 0);
    }
}
