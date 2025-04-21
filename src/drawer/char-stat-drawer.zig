const std = @import("std");
const rl = @import("raylib");
const State = @import("../state.zig").State;
const cnst = @import("../constants.zig");
const CharState = @import("../common_enums.zig").CharState;

var ch_buff_arr: [17]u8 = undefined;
var ch_buffer = std.heap.FixedBufferAllocator.init(&ch_buff_arr);

pub const CharStatDrawer = struct {
    const This: type = @This();
    const font_path = "./resources/RobotoMono-Regular.ttf";
    const font_size = 24;
    const small_font_size = 12;

    state: *State,
    font: rl.Font,
    small_font: rl.Font,
    ch_size: rl.Vector2,
    text_margin: i32,

    pub fn init(state: *State, margin: i32) CharStatDrawer {
        var chars: [cnst.chars.len]i32 = undefined;
        @memcpy(chars[0..], cnst.chars[0..]);
        const font = rl.loadFontEx(font_path, font_size, chars[0..]) catch unreachable;
        const small_font = rl.loadFontEx(font_path, small_font_size, chars[0..]) catch unreachable;
        const ch_size = rl.measureTextEx(small_font, "a", small_font_size, 1);
        return .{
            .state = state,
            .font = font,
            .small_font = small_font,
            .ch_size = ch_size,
            .text_margin = margin,
        };
    }

    pub fn drawText(self: This) rl.Vector2 {
        const box_size = (self.ch_size.x * 10);
        const text_width = @min(rl.getRenderWidth() - self.text_margin * 2, 900);
        const max_width: f32 = @as(f32, @floatFromInt(text_width)) / box_size;
        const start = rl.Vector2{ .x = @as(f32, @floatFromInt(rl.getRenderWidth() - text_width)) / 2, .y = 20 };

        const state = self.state;

        var line: f32 = 0;
        var symbol: f32 = 0;
        for (state.symbol_stats.items) |stat| {
            if (std.unicode.utf8ByteSequenceLength(stat.smb[0]) catch unreachable != stat.smb.len) continue;
            const point = start.add(.{ .x = box_size * symbol, .y = (font_size + 2 * small_font_size + 3) * line });
            rl.drawTextEx(self.font, stat.smb, point, font_size, 1, cnst.accent_color);

            ch_buffer.reset();
            const err: f32 = if (stat.n != 0)
                100 - @as(f32, @floatFromInt(stat.n_error * 100)) / @as(f32, @floatFromInt(stat.n))
            else
                0;
            const er_color = getMixedColor(err, 90, 95, 100, cnst.red_color, cnst.yellow_color, cnst.green_color);
            const text1 = std.fmt.allocPrintZ(
                ch_buffer.allocator(),
                "{d:.1}%",
                .{err},
            ) catch unreachable;
            rl.drawTextEx(self.small_font, text1, point.add(.{ .x = 0, .y = font_size + 1 }), small_font_size, 1, er_color);

            ch_buffer.reset();
            const cpm = cpm: {
                if (stat.sum_time == null or stat.sum_time.? == 0) break :cpm null;
                const cpm: i128 = @intCast(@divFloor(60 * 1000 * 1000 * 1000 * @as(i128, stat.n_time), stat.sum_time.?));
                break :cpm cpm;
            };
            const mean = if (state.cpm == 0) 200 else state.cpm;
            const cpm_color = if (cpm) |c|
                getMixedColor(
                    @floatFromInt(c),
                    @floatFromInt(mean - 100),
                    @floatFromInt(mean - 50),
                    @floatFromInt(mean + 50),
                    cnst.red_color,
                    cnst.yellow_color,
                    cnst.green_color,
                )
            else
                cnst.dark_red_color;
            const text2 = t: {
                if (cpm == null) break :t "none";
                break :t std.fmt.allocPrintZ(
                    ch_buffer.allocator(),
                    "cpm {d}",
                    .{cpm.?},
                ) catch unreachable;
            };
            rl.drawTextEx(self.small_font, text2, point.add(.{ .x = 0, .y = font_size + small_font_size + 2 }), small_font_size, 1, cpm_color);

            symbol += 1;
            if (symbol >= max_width) {
                line += 1;
                symbol = 0;
            }
        }
        if (symbol != 0) line += 1;
        return start.add(.{ .x = 0, .y = (font_size + 2 * small_font_size + 3) * line });
    }
};

fn getMixedColor(x: f64, min: f64, middle: f64, max: f64, min_color: rl.Color, middle_color: rl.Color, max_color: rl.Color) rl.Color {
    std.debug.assert(min <= middle);
    std.debug.assert(middle <= max);

    if (x <= min) return min_color;
    if (x >= max) return max_color;
    if (x < middle) {
        const a: f64 = if (middle == min) 1 else (middle - x) / (middle - min);
        // std.debug.print("x {d} min {d} middle {d} max {d} a {d} \n", .{ x, min, middle, max, a });
        return rl.Color{
            .a = 0xFF,
            .r = mix(a, min_color.r, middle_color.r),
            .g = mix(a, min_color.g, middle_color.g),
            .b = mix(a, min_color.b, middle_color.b),
        };
    }
    const a: f64 = if (max == middle) 1 else (max - x) / (max - middle);
    return rl.Color{
        .a = 0xFF,
        .r = mix(a, middle_color.r, max_color.r),
        .g = mix(a, middle_color.g, max_color.g),
        .b = mix(a, middle_color.b, max_color.b),
    };
}

fn mix(a: f64, x: u8, y: u8) u8 {
    const ax: f64 = @floatFromInt(x);
    const ay: f64 = @floatFromInt(y);
    const result: f64 = @floor((a * ax) + (1 - a) * ay);
    // std.debug.print("ax {d} ay {d} a {d} result {d} \n", .{ a * ax, (a - 1) * ay, a, result });
    return @intFromFloat(result);
}
