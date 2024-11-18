const TitleScreen = @import("title.zig");
const GameScreen = @import("game.zig");

const ScreenType = enum {
    title,
    game,
};

// TODO: Finish
pub const Current = union(ScreenType) {
    title: TitleScreen,
    game: GameScreen,
};
