const std = @import("std");

const en_path = "resources/word/en";
var da = std.heap.DebugAllocator(.{}).init;
var allocator = da.allocator();

pub fn readEn() void {
    var dir = std.fs.cwd().openDir(
        en_path,
        .{
            .access_sub_paths = false, // default is true
            .iterate = true,
        },
    ) catch unreachable;
    var it = dir.iterate();
    while (it.next() catch unreachable) |entry| {
        if (entry.kind == .file and entry.kind != .directory) {
            std.debug.print("File Name: {s}\n", .{entry.name});
            var file = dir.openFile(entry.name, .{ .mode = .read_only }) catch unreachable;
            const stats = file.stat() catch unreachable;
            var file_buff = allocator.alloc(u8, stats.size) catch unreachable;
            defer allocator.free(file_buff);
            const n = file.readAll(file_buff[0..]) catch unreachable;
            std.debug.assert(n == stats.size);
        }
    }
}
