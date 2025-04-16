const std = @import("std");
const rl = @import("raylib");
const State = @import("../state.zig").State;
const cnst = @import("../constants.zig");
const CharState = @import("../common_enums.zig").CharState;

var ch_buff_arr: [17]u8 = undefined;
var ch_buffer = std.heap.FixedBufferAllocator.init(&ch_buff_arr);
var str_buff_arr: [1024]u8 = undefined;
var str_buff = std.heap.FixedBufferAllocator.init(&str_buff_arr);

pub const StatDrawer = struct {
    const This: type = @This();
    const font_path = "./resources/RobotoMono-Regular.ttf";
    const font_size = 32;

    state: *State,
    font: rl.Font,
    ch_size: rl.Vector2,

    pub fn init(state: *State) StatDrawer {
        var chars: [cnst.chars.len]i32 = undefined;
        @memcpy(chars[0..], cnst.chars[0..]);
        const font = rl.loadFontEx(font_path, font_size, chars[0..]) catch unreachable;
        const ch_size = rl.measureTextEx(font, "a", font_size, 1);
        return .{
            .state = state,
            .font = font,
            .ch_size = ch_size,
        };
    }

    pub fn drawStats(self: StatDrawer) void {
        var start = rl.Vector2{ .x = 100, .y = 100 };
        var str: [3:0]u8 = undefined;
        for (self.state.symbol_stats.items, 0..) |st, i| {
            if (i > 9) break;

            for (str, 0..) |_, j| str[j] = ' ';
            @memcpy(str[(3 - st.smb.len)..3], st.smb);
            const e: u64 = if (st.n == 0) 0 else @divFloor((st.n_error * 1000), st.n);
            const f: f64 = @floatFromInt(e / 10);
            str_buff.reset();
            const st_text = std.fmt.allocPrintZ(str_buff.allocator(), "{s}: cpm {d} with {d:.1} correctness", .{
                str,
                if (st.sum_time) |time|
                    @divFloor(60 * 1000 * 1000 * 1000 * @as(i128, st.n_time), time)
                else
                    0,
                100 - f,
            }) catch unreachable;
            rl.drawTextEx(self.font, st_text, start, font_size, 1, cnst.accent_color);
            start = start.add(.{ .x = 0, .y = font_size + 1 });
        }
    }
};
