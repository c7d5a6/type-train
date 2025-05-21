const std = @import("std");
const rl = @import("raylib");
const State = @import("../state.zig").State;
const cnst = @import("../constants.zig");
const CharState = @import("../common_enums.zig").CharState;
const CharStatDrawer = @import("char-stat-drawer.zig").CharStatDrawer;

var ch_buff_arr: [17]u8 = undefined;
var ch_buffer = std.heap.FixedBufferAllocator.init(&ch_buff_arr);

pub const TextDrawer = struct {
    const This: type = @This();
    const font_path = "./resources/RobotoMono-Regular.ttf";
    const font_size = 40;
    const text_margin = 100;

    state: *State,
    font: rl.Font,
    ch_size: rl.Vector2,
    char_drawer: CharStatDrawer,

    pub fn init(state: *State) TextDrawer {
        var chars: [cnst.chars.len]i32 = undefined;
        @memcpy(chars[0..], cnst.chars[0..]);
        const font = rl.loadFontEx(font_path, font_size, chars[0..]) catch unreachable;
        // rl.setTextureFilter(font.texture, .trilinear);
        const ch_size = rl.measureTextEx(font, "a", font_size, 1);
        return .{
            .state = state,
            .font = font,
            .ch_size = ch_size,
            .char_drawer = CharStatDrawer.init(state, text_margin),
        };
    }

    pub fn drawText(self: This) void {
        const char_end = self.char_drawer.drawText();

        const text_width = @min(rl.getRenderWidth() - text_margin * 2, 900);
        const max_width: f32 = @as(f32, @floatFromInt(text_width)) / self.ch_size.x - 8;
        const point: rl.Vector2 = .{ .x = @as(f32, @floatFromInt(rl.getRenderWidth() - text_width)) / 2, .y = @max(200, char_end.y + 70) };
        const start = point;

        ch_buffer.reset();
        const time = std.fmt.allocPrintZ(ch_buffer.allocator(), "cpm: {d}", .{self.state.cpm}) catch unreachable;
        rl.drawTextEx(self.font, time, point.add(.{ .x = 0, .y = -50 }), font_size, 1, cnst.accent_color);
        //

        const state = self.state;
        const exercise = state.exercise.items;
        const typed = state.typed.items;

        var line: f32 = 0;
        var symbol: f32 = 0;
        var ie: u32 = 0;
        var it: u32 = 0;
        var drawn = false;
        var prev_ch: u21 = 0;
        while (exercise.len > ie or typed.len > it) {
            const ch_state: CharState = st: {
                if (exercise.len <= ie) break :st .wrong_over;
                if (typed.len <= it) break :st .not_typed;
                if (exercise[ie] == typed[it]) break :st .correct;
                if (exercise[ie] == ' ') break :st .wrong_over;
                if (typed[it] == ' ') break :st .not_typed;
                break :st .wrong;
            };
            const ch = switch (ch_state) {
                .not_typed, .wrong, .correct => exercise[ie],
                .wrong_over => typed[it],
            };

            if (symbol >= max_width and prev_ch == ' ') {
                symbol = 0;
                line += 1;
            }

            self.drawChar(start, line, symbol, ch, ch_state, (it == typed.len and !drawn));
            drawn = it == typed.len;

            switch (ch_state) {
                .not_typed => ie += 1,
                .correct, .wrong => {
                    ie += 1;
                    it += 1;
                },
                .wrong_over => it += 1,
            }

            symbol += 1;
            prev_ch = ch;
        }
    }

    fn drawChar(self: This, start: rl.Vector2, line: f32, symbol: f32, ch: u21, ch_state: CharState, draw_rect: bool) void {
        const color = switch (ch_state) {
            .correct => cnst.text_color,
            .wrong => cnst.danger_color,
            .wrong_over => cnst.dark_red_color,
            .not_typed => cnst.grey_color,
        };
        const font = self.font;
        const point = start.add(self.ch_size.multiply(.{ .x = symbol, .y = line }));
        // const text = [_]u8{ch};
        var text: [4]u8 = undefined;
        const n = std.unicode.utf8Encode(@intCast(ch), &text) catch unreachable;
        ch_buffer.reset();
        const t = std.mem.Allocator.dupeZ(ch_buffer.allocator(), u8, text[0..n]) catch unreachable;
        if (draw_rect) {
            rl.drawRectangleLinesEx(.{
                .x = point.x,
                .y = point.y,
                .width = self.ch_size.x,
                .height = self.ch_size.y,
            }, 1, cnst.accent_color);
        }
        rl.drawTextEx(font, t, point, font_size, 1, color);
    }
};
