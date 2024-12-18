const std = @import("std");
const rl = @cImport(@cInclude("raylib.h"));

const TitleScreen = @This();
const Allocator = std.mem.Allocator;

pub const Option = struct {
    text: []const u8,
    flag_to_flip: *bool,
};

allocator: *const Allocator,
title: []const u8,
options: []const Option,
selected: usize = 0,

pub fn deinit(self: *TitleScreen) void {
    self.allocator.*.free(self.options);
}

pub fn handleInput(self: *TitleScreen) void {
    if (rl.IsKeyPressed(rl.KEY_UP)) {
        self.selectPrevOption();
    }
    if (rl.IsKeyPressed(rl.KEY_DOWN)) {
        self.selectNextOption();
    }
    if (rl.IsKeyPressed(rl.KEY_ENTER) or rl.IsKeyPressed(rl.KEY_SPACE)) {
        self.options[self.selected].flag_to_flip.* = !self.options[self.selected].flag_to_flip.*;
    }
}

fn selectNextOption(self: *TitleScreen) void {
    if (self.selected == self.options.len - 1) {
        self.selected = 0;
        return;
    }

    self.selected += 1;
}

fn selectPrevOption(self: *TitleScreen) void {
    if (self.selected == 0) {
        self.selected = self.options.len - 1;
        return;
    }

    self.selected -= 1;
}

pub fn draw(self: *TitleScreen, screen_width: *const u16) void {
    const half_screen_x = screen_width.* / 2;

    const title_width = rl.MeasureText(self.title.ptr, 50);
    const title_centred_x = half_screen_x - @divExact(title_width, 2);

    rl.DrawText(self.title.ptr, title_centred_x, 100, 50, rl.WHITE);

    var next_opt_y: u16 = 200;
    for (self.options, 0..) |opt, index| {
        const opt_text = opt.text.ptr;
        const opt_width = rl.MeasureText(opt_text, 25);
        const opt_centred_x = half_screen_x - @divExact(opt_width, 2);
        const opt_colour = if (index == self.selected) rl.YELLOW else rl.WHITE;

        rl.DrawText(opt_text, opt_centred_x, next_opt_y, 25, opt_colour);

        next_opt_y += 50;
    }
}
