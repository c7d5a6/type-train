const std = @import("std");
const file = @import("file-reader.zig");
const State = @import("state.zig").State;
const SymbolStat = @import("state.zig").SymbolStat;
const cnst = @import("constants.zig");
const isLenOneUtf8 = @import("utils.zig").isLenOneUtf8;
const has = @import("utils.zig").has;

var temp_da = std.heap.DebugAllocator(.{}).init;
var temp_arena = std.heap.ArenaAllocator.init(temp_da.allocator());

var word_da = std.heap.DebugAllocator(.{}).init;
var word_arena = std.heap.ArenaAllocator.init(word_da.allocator());

var storage_da = std.heap.DebugAllocator(.{}).init;
var storage: std.ArrayList(StorWord) = std.ArrayList(StorWord).init(storage_da.allocator());

var symbol_buff: [cnst.char_len * 3]u8 = undefined;
var symbol_all = std.heap.FixedBufferAllocator.init(&symbol_buff);
pub var symbols = std.ArrayList(u21).init(symbol_all.allocator());

const StorWord = struct {
    word: []u8,
    score: u128 = 0,
};

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
        if (!hasStorWord(storage.items, word)) {
            storage.append(.{ .word = word[0..] }) catch unreachable;
            var i: u32 = 0;
            while (i < word.len) {
                const n = std.unicode.utf8ByteSequenceLength(word[i]) catch unreachable;
                const c = std.unicode.utf8Decode(word[i .. i + n]) catch unreachable;
                const hasSmb = hasSmb: {
                    for (symbols.items) |s| {
                        if (s == c) break :hasSmb true;
                    }
                    break :hasSmb false;
                };
                if (!hasSmb)
                    symbols.append(c) catch unreachable;
                i += n;
            }
        }
    }
    std.debug.print("Symbols:\n", .{});
    for (symbols.items, 0..) |s, i| {
        var str = symbol_all.allocator().alloc(u8, 4) catch unreachable;
        defer symbol_all.allocator().free(str);
        _ = std.unicode.utf8Encode(s, str[0..]) catch unreachable;
        std.debug.print("\t{d}. {s}\n", .{ i, str });
    }
}

pub fn createAndInitExcercise(state: *State) void {
    defer _ = temp_arena.reset(.free_all);
    var words: std.ArrayList([]u8) = std.ArrayList([]u8).init(temp_arena.allocator());

    calculateScore(storage.items, state.*);
    var r = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
    r.random().shuffle(StorWord, storage.items);
    std.mem.sort(StorWord, storage.items, .{}, lessThanSW);
    std.debug.print("Top 10 sorted words with score\n", .{});
    for (storage.items, 0..) |sw, i| {
        if (i > 10) break;
        if (sw.score > 0) {
            const c = @divFloor(60 * 1000 * 1000 * 1000, sw.score);
            std.debug.print("\t{d}: {s} in {d}\n", .{ i, sw.word, c });
        }
    }

    // var r = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
    // r.random().shuffle(StorWord, storage.items);

    var slow: ?SymbolStat = null;
    for (state.symbol_stats.items) |stat| {
        if (stat.sum_time == null) continue;
        if (!isLenOneUtf8(stat.smb)) continue;
        if (slow == null or slow.?.sum_time == null) {
            slow = stat;
            continue;
        }
        const stat_time = stat.sum_time.?;
        const stat_ntime = stat.n_time;
        const sl_time = slow.?.sum_time.?;
        const sl_ntime = slow.?.n_time;
        if (stat_time * sl_ntime > sl_time * stat_ntime) {
            slow = stat;
        }
    }
    std.debug.print("Slow item is {s}:{?}", .{ if (slow == null) "-" else slow.?.smb, slow });

    var word_count: u8 = 0;
    var processed: u64 = 0;
    lbl: while (word_count < state.exercise_len and processed < state.symbol_stats.items.len) {
        const stat = &state.symbol_stats.items[processed];
        const smb = stat.smb;
        if (slow) |sl| {
            for (storage.items) |sw| {
                const word = sw.word;
                if (has(word, sl.smb) and has(word, smb) and !hasWord(words.items, word)) {
                    word_count += 1;
                    processed += 1;
                    words.append(word) catch unreachable;
                    continue :lbl;
                }
            }
        }
        for (storage.items) |sw| {
            const word = sw.word;
            if (has(word, smb) and !hasWord(words.items, word)) {
                word_count += 1;
                processed += 1;
                words.append(word) catch unreachable;
                continue :lbl;
            }
        }
        processed += 1;
    }
    for (storage.items) |sw| {
        const word = sw.word;
        if (word_count >= state.exercise_len) break;
        if (!hasWord(words.items, word)) {
            word_count += 1;
            words.append(word) catch unreachable;
        }
    }

    state.init_exercise(words.items, symbols.items);
}

fn lessThanSW(v: @TypeOf(.{}), l: StorWord, r: StorWord) bool {
    _ = v;
    return l.score > r.score;
}

fn calculateScore(list: []StorWord, state: State) void {
    var i: usize = 0;
    while (i < list.len) {
        const word = list[i].word;
        var j: usize = 0;
        var time: u128 = 0;
        var n: usize = 0;
        while (j < word.len) {
            for (state.symbol_stats.items) |st| {
                if (st.sum_time == null) continue;
                if (j + st.smb.len > word.len) continue;
                if (std.mem.eql(u8, st.smb, word[j .. j + st.smb.len])) {
                    time += @intCast(st.sum_time.?);
                    n += st.n_time;
                }
            }
            j += std.unicode.utf8ByteSequenceLength(word[j]) catch unreachable;
        }
        if (n != 0) {
            list[i].score = @divFloor(time, n);
        }
        i += 1;
    }
}

fn hasStorWord(list: []const StorWord, word: []const u8) bool {
    for (list) |sw| {
        const w = sw.word;
        if (w.len == word.len) {
            if (std.mem.eql(u8, w, word)) return true;
        }
    }
    return false;
}

fn hasWord(list: []const []const u8, word: []const u8) bool {
    for (list) |w| {
        if (w.len == word.len) {
            if (std.mem.eql(u8, w, word)) return true;
        }
    }
    return false;
}
