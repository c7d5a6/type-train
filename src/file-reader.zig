const std = @import("std");

const en_path = "resources/word/zig";
const initial_capacity = 1000 * 1000;
const Words = std.ArrayList([]const u8);

pub fn readEn(a: std.mem.Allocator) Words {
    var result = Words.initCapacity(a, initial_capacity) catch unreachable;
    const dir = std.fs.cwd().openDir(
        en_path,
        .{
            // .access_sub_paths = false, // default is true
            .iterate = true,
        },
    ) catch unreachable;
    readDir(a, dir, &result);
    return result;
}

fn readDir(a: std.mem.Allocator, dir: std.fs.Dir, words: *Words) void {
    var it = dir.iterate();
    while (it.next() catch unreachable) |entry| {
        switch (entry.kind) {
            .file => {
                var file = dir.openFile(entry.name, .{ .mode = .read_only }) catch unreachable;
                if (std.mem.eql(u8, ".tar", entry.name[entry.name.len - 4 .. entry.name.len])) continue;
                if (std.mem.eql(u8, ".xz", entry.name[entry.name.len - 3 .. entry.name.len])) continue;
                if (std.mem.eql(u8, ".lzma", entry.name[entry.name.len - 5 .. entry.name.len])) continue;
                if (std.mem.eql(u8, "input", entry.name[entry.name.len - 5 .. entry.name.len])) continue;
                if (std.mem.eql(u8, "xpect", entry.name[entry.name.len - 5 .. entry.name.len])) continue;
                if (std.mem.eql(u8, ".tzif", entry.name[entry.name.len - 5 .. entry.name.len])) continue;
                std.debug.print("File Name: {s}\n", .{entry.name});
                const stats = file.stat() catch unreachable;
                var file_buff = a.alloc(u8, stats.size) catch unreachable;
                const n = file.readAll(file_buff[0..]) catch unreachable;
                std.debug.assert(n == stats.size);
                addWords(words, file_buff) catch {
                    std.debug.print("141 in {any}\n", .{stats});
                    continue;
                };
            },
            .directory => {
                const next_dir = dir.openDir(entry.name, .{ .iterate = true }) catch unreachable;
                readDir(a, next_dir, words);
            },
            else => {},
        }
        if (entry.kind == .file and entry.kind != .directory) {}
    }
}

const CharacterErrors = error{
    UnparsableCharacter,
};

fn addWords(arr: *Words, text: []const u8) CharacterErrors!void {
    var i: u32 = 0;
    var j: u32 = 0;
    while (i < text.len) {
        while (j < text.len) {
            if (skipable(text[j])) break;
            switch (text[j]) {
                134, 141, 160, 170, 254, 255 => return CharacterErrors.UnparsableCharacter,
                else => {},
            }
            j += 1;
        }
        if (i != j) {
            if (j - i < 7)
                arr.append(text[i..j]) catch unreachable;
        } else j += 1;
        i = j;
    }
}

fn skipable(c: u8) bool {
    return switch (c) {
        ' ', '\n', 0, 1, 12 => true,
        else => false,
    };
}
