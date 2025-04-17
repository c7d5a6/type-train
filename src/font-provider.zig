const rl = @import("raylib");
const cnst = @import("constants.zig");

pub const FontProvider = struct {
    const font_path = "./resources/RobotoMono-Regular.ttf";

    font_size: usize = 40,
    font: rl.Font = null,

    pub fn load(self: *@This()) void {
        var chars: [cnst.chars.len]i32 = undefined;
        @memcpy(chars[0..], cnst.chars[0..]);
        self.font = rl.loadFontEx(font_path, self.font_size, chars[0..]) catch unreachable;
    }
};
