const std = @import("std");
const file = @import("file-reader.zig");
const State = @import("state.zig").State;
const cnst = @import("constants.zig");

var temp_da = std.heap.DebugAllocator(.{}).init;
var temp_arena = std.heap.ArenaAllocator.init(temp_da.allocator());

var word_da = std.heap.DebugAllocator(.{}).init;
var word_arena = std.heap.ArenaAllocator.init(word_da.allocator());

var storage_da = std.heap.DebugAllocator(.{}).init;
var storage: std.ArrayList([]u8) = std.ArrayList([]u8).init(storage_da.allocator());

var symbol_buff: [cnst.char_len * 3]u8 = undefined;
var symbol_all = std.heap.FixedBufferAllocator.init(&symbol_buff);
pub var symbols = std.ArrayList(u21).init(symbol_all.allocator());

pub fn load() void {
    defer _ = temp_arena.reset(.free_all);
    _ = word_arena.reset(.retain_capacity);
    _ = word_arena.allocator().alloc(u21, 50 * 1000 * 25 * 4) catch unreachable;
    _ = word_arena.reset(.retain_capacity);
    symbols.clearRetainingCapacity();
    storage.clearRetainingCapacity();

    const file_words = file.readEn(temp_arena.allocator());
    for (file_words.items) |w| {
        var word = word_arena.allocator().alloc(u8, w.len) catch unreachable;
        @memcpy(word[0..], w);
        if (!hasWord(storage.items, word)) {
            storage.append(word[0..]) catch unreachable;
            var i: u32 = 0;
            while (i < word.len) {
                const n = std.unicode.utf8ByteSequenceLength(word[i]) catch unreachable;
                const c = std.unicode.utf8Decode(word[i .. i + n]) catch unreachable;
                const has = has: {
                    for (symbols.items) |s| {
                        if (s == c) break :has true;
                    }
                    break :has false;
                };
                if (!has)
                    symbols.append(c) catch unreachable;
                i += n;
            }
        }
    }
    std.debug.print("symbols {any}\n", .{symbols.items});
}

pub fn createAndInitExcercise(state: *State) void {
    defer _ = temp_arena.reset(.free_all);
    var words: std.ArrayList([]u8) = std.ArrayList([]u8).init(temp_arena.allocator());

    var r = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
    r.random().shuffle([]u8, storage.items);

    var word_count: u8 = 0;
    var processed: u64 = 0;
    lbl: while (word_count < state.exercise_len and processed < state.symbol_stats.items.len) {
        var stat = &state.symbol_stats.items[processed];
        const smb = stat.smb;
        for (storage.items) |word| {
            var j: u8 = 0;
            while (j + smb.len <= word.len) {
                if (std.mem.eql(u8, word[j .. j + smb.len], smb) and !hasWord(words.items, word)) {
                    stat.n_error -= @divFloor(stat.n_error, 2);
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

    state.init_exercise(words.items, symbols.items);
}

fn hasWord(list: []const []const u8, word: []const u8) bool {
    for (list) |w| {
        if (w.len == word.len) {
            if (std.mem.eql(u8, w, word)) return true;
        }
    }
    return false;
}
