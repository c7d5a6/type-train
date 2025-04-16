const std = @import("std");

pub fn isLenOneUtf8(str: []u8) bool {
    if (str.len == 0) return false;
    const len = std.unicode.utf8ByteSequenceLength(str[0]) catch return false;
    return len == str.len;
}

pub fn has(word: []u8, str: []u8) bool {
    std.debug.assert(str.len > 0);

    if (str.len > word.len) return false;

    var i: usize = 0;
    while (i + str.len <= word.len) {
        if (std.mem.eql(u8, word[i .. i + str.len], str))
            return true;
        i += 1;
    }
    return false;
}
