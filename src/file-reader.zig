const std = @import("std");

const en_path = "resources/word/test";
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
                std.debug.print("File Name: {s}\n", .{entry.name});
                var file = dir.openFile(entry.name, .{ .mode = .read_only }) catch unreachable;
                const stats = file.stat() catch unreachable;
                var file_buff = a.alloc(u8, stats.size) catch unreachable;
                const n = file.readAll(file_buff[0..]) catch unreachable;
                std.debug.assert(n == stats.size);
                addWords(words, file_buff);
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

fn addWords(arr: *Words, text: []const u8) void {
    var i: u32 = 0;
    var j: u32 = 0;
    while (i < text.len) {
        while (j < text.len) {
            if (skipable(text[j])) break;
            j += 1;
        }
        if (i != j) {
            arr.append(text[i..j]) catch unreachable;
        } else j += 1;
        i = j;
    }
}

fn skipable(c: u8) bool {
    return switch (c) {
        ' ', '\n' => true,
        else => false,
    };
}
