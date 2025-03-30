const rl = @import("raylib");
const std = @import("std");

pub const text_color = hexToColor(0xF3F2EBFF); // F3F2EB
pub const grey_color = hexToColor(0x8C8E94FF); // 8C8E94
pub const accent_color = hexToColor(0xD4A344FF); // D4A344
pub const dark_red_color = hexToColor(0x9D5648FF); // 9D5648
pub const background_color = hexToColor(0x282828FF); //282828            //
//Old Gold #d7a343 Primary
//Thunder #292629 Info
//Chelsea Cucumber #76ab4c Success
//Buttercup #f39b14 Warning
//Pomegranate #f44336 Danger
pub const danger_color = hexToColor(0xF44336FF);

pub fn hexToColor(hex: u32) rl.Color {
    const r = ((hex & 0xFF000000) >> 16) >> 8;
    const g = (hex & 0x00FF0000) >> 16;
    const b = (hex & 0x0000FF00) >> 8;
    const a = hex & 0x000000FF;

    return rl.Color.init(@intCast(r), @intCast(g), @intCast(b), @intCast(a));
}
