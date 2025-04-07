const rl = @import("raylib");
const std = @import("std");

pub const max_characters_test = 25 * 100 * 4 + 4;

pub const text_color = hexToColor(0xF3F2EBFF); // F3F2EB
pub const grey_color = hexToColor(0x6C6E74FF); // 8C8E94
pub const accent_color = hexToColor(0xD4A344FF); // D4A344
pub const dark_red_color = hexToColor(0x9D5648FF); // 9D5648
pub const background_color = hexToColor(0x282828FF); //282828            //
//Old Gold #d7a343 Primary
//Thunder #292629 Info
pub const green_color = hexToColor(0x76AB4CFF); //Chelsea Cucumber #76ab4c Success
pub const red_color = hexToColor(0xF44336FF); //Pomegranate #f44336 Danger
pub const yellow_color = hexToColor(0xF39B14FF); //Buttercup #f39b14 Warning

pub const danger_color = hexToColor(0xF44336FF); //#f44336

pub fn hexToColor(hex: u32) rl.Color {
    const r = ((hex & 0xFF000000) >> 16) >> 8;
    const g = (hex & 0x00FF0000) >> 16;
    const b = (hex & 0x0000FF00) >> 8;
    const a = hex & 0x000000FF;

    return rl.Color.init(@intCast(r), @intCast(g), @intCast(b), @intCast(a));
}

fn getChars(comptime from: i32, comptime to: i32) []const i32 {
    const r = lbl: {
        var res: [to - from + 1]i32 = undefined;
        var i: u8 = 0;
        while (from + i <= to) {
            res[i] = from + i;
            i += 1;
        }
        break :lbl res;
    };
    return &r;
}
const latin_upper = getChars(0x0041, 0x005A);
const latin_lower = getChars(0x0061, 0x007A);
const greek_upper = getChars(0x0391, 0x03A9);
const greek_lower = getChars(0x03B1, 0x03C9);
const cyril_upper = getChars(0x0410, 0x042F);
const cyril_lower = getChars(0x0430, 0x044F);
const numbers = getChars(0x0030, 0x0039);
const space = getChars(0x0020, 0x002F);
const symbols = getChars(0x003A, 0x0040);
const brackets = getChars(0x005B, 0x0060);
const symbols_2 = getChars(0x007B, 0x007E);
const currency = getChars(0x0024, 0x0024);
const currency2 = getChars(0x20AC, 0x20AC);
const currency3 = getChars(0x00A3, 0x00A5);
const diacritic = getChars(0x0300, 0x036F);
pub const char_len = latin_upper.len + latin_lower.len + greek_upper.len + greek_lower.len + cyril_upper.len + cyril_lower.len + numbers.len + space.len + symbols.len + brackets.len + symbols_2.len + currency.len + currency2.len + currency3.len + diacritic.len;

pub const chars = chars: {
    const r = lbl: {
        var arrs: [15][]const i32 = undefined;
        arrs[0] = latin_upper;
        arrs[1] = latin_lower;
        arrs[2] = greek_upper;
        arrs[3] = greek_lower;
        arrs[4] = cyril_upper;
        arrs[5] = cyril_lower;
        arrs[6] = numbers;
        arrs[7] = space;
        arrs[8] = symbols;
        arrs[9] = brackets;
        arrs[10] = symbols_2;
        arrs[11] = currency;
        arrs[12] = currency2;
        arrs[13] = currency3;
        arrs[14] = diacritic;
        var res: [char_len]i32 = undefined;
        var i: u32 = 0;
        var x: u32 = 0;
        while (i < arrs.len) {
            @memcpy(res[x .. x + arrs[i].len], arrs[i]);
            x += arrs[i].len;
            i += 1;
        }
        break :lbl res;
    };

    break :chars &r;
};
