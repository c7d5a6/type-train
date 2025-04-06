const std = @import("std");
const file = @import("file-reader.zig");
const State = @import("state.zig").State;

var temp_da = std.heap.DebugAllocator(.{}).init;
var temp_arena = std.heap.ArenaAllocator.init(temp_da.allocator());
var word_da = std.heap.DebugAllocator(.{}).init;
var word_arena = std.heap.ArenaAllocator.init(word_da.allocator());
var storage_da = std.heap.DebugAllocator(.{}).init;
var storage: std.ArrayList([]u8) = std.ArrayList([]u8).init(storage_da.allocator());

pub fn load() void {
    defer _ = temp_arena.reset(.free_all);
    _ = word_arena.reset(.retain_capacity);
    _ = word_arena.allocator().alloc(u21, 50 * 1000 * 25 * 4) catch unreachable;
    _ = word_arena.reset(.retain_capacity);
    storage.clearRetainingCapacity();

    const file_words = file.readEn(temp_arena.allocator());
    for (file_words.items) |w| {
        var word = word_arena.allocator().alloc(u8, w.len) catch unreachable;
        @memcpy(word[0..], w);
        if (!hasWord(storage.items, word))
            storage.append(word[0..]) catch unreachable;
    }
    for (storage.items) |w| std.debug.print("\t*{s}\n", .{w});
}

pub fn createAndInitExcercise(state: *State) void {
    defer _ = temp_arena.reset(.free_all);
    var words: std.ArrayList([]u8) = std.ArrayList([]u8).init(temp_arena.allocator());

    var r = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
    r.random().shuffle([]u8, storage.items);

    var word_count: u8 = 0;
    var processed: u64 = 0;
    lbl: while (word_count < state.exercise_len and processed < state.symbol_stats.items.len) {
        const smb = state.symbol_stats.items[word_count].smb;
        for (storage.items) |word| {
            var j: u8 = 0;
            while (j + smb.len <= word.len) {
                if (std.mem.eql(u8, word[j .. j + smb.len], smb) and !hasWord(words.items, word)) {
                    word_count += 1;
                    processed += 1;
                    words.append(word) catch unreachable;
                    continue :lbl;
                } else j += 1;
            }
        }
        processed += 1;
    }
    for (storage.items) |word| {
        if (word_count >= state.exercise_len) break;
        if (!hasWord(words.items, word)) {
            word_count += 1;
            words.append(word) catch unreachable;
        }
    }

    state.init_exercise(words.items);
}

fn hasWord(list: []const []const u8, word: []const u8) bool {
    for (list) |w| {
        if (w.len == word.len) {
            return std.mem.eql(u8, w, word);
        }
    }
    return false;
}
