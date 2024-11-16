const TitleScreen = @This();
const rl = @cImport(@cInclude("raylib.h"));

title: []const u8,
options: [2][]const u8,
selected: i8 = 0,

pub fn selectNextOption(self: *TitleScreen) !void {
    var next_opt = self.selected + 1;
    if (next_opt == self.options.len) {
        next_opt = 0;
    }

    self.selected = next_opt;
}

pub fn selectPrevOption(self: *TitleScreen) !void {
    var prev_opt = self.selected - 1;
    if (prev_opt == -1) {
        prev_opt = self.options.len - 1;
    }

    self.selected = prev_opt;
}

pub fn draw(self: *TitleScreen, screen_width: *const u16) !void {
    const half_screen_x = screen_width.* / 2;

    const title_width = rl.MeasureText(self.title.ptr, 50);
    const centred_start = half_screen_x - @divExact(title_width, 2);

    rl.DrawText(self.title.ptr, centred_start, 100, 50, rl.WHITE);

    var next_opt_y: u16 = 200;
    for (self.options, 0..) |opt, index| {
        const opt_width = rl.MeasureText(opt.ptr, 25);
        const opt_centred_x = half_screen_x - @divExact(opt_width, 2);
        const opt_colour = if (index == self.selected) rl.YELLOW else rl.WHITE;

        rl.DrawText(opt.ptr, opt_centred_x, next_opt_y, 25, opt_colour);

        next_opt_y += 50;
    }
}
