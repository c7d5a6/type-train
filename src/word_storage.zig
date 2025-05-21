const std = @import("std");
const file = @import("file-reader.zig");
const State = @import("state.zig").State;
const SymbolStat = @import("state.zig").SymbolStat;
const cnst = @import("constants.zig");
const isLenOneUtf8 = @import("utils.zig").isLenOneUtf8;
const has = @import("utils.zig").has;

// var temp_da = std.heap.DebugAllocator(.{}).init;
const temp_da = std.heap.c_allocator;
var temp_arena = std.heap.ArenaAllocator.init(temp_da);

const word_da = std.heap.c_allocator;
var word_arena = std.heap.ArenaAllocator.init(word_da);

// var storage_da = std.heap.DebugAllocator(.{}).init;
const storage_da = std.heap.c_allocator;
var storage: std.ArrayList(StorWord) = std.ArrayList(StorWord).init(storage_da);

var symbol_buff: [cnst.char_len * 1000]u8 = undefined;
var symbol_all = std.heap.FixedBufferAllocator.init(&symbol_buff);
pub var symbols = std.ArrayList(u21).init(symbol_all.allocator());

const StorWord = struct {
    word: []u8,
    score: u128 = 0,
};

pub fn load() void {
    std.debug.print("LOAD WORDS:...\n", .{});
    defer _ = temp_arena.reset(.free_all);
    _ = word_arena.reset(.retain_capacity);
    _ = word_arena.allocator().alloc(u21, 50 * 1000 * 25 * 4) catch unreachable;
    _ = word_arena.reset(.retain_capacity);
    symbols.clearRetainingCapacity();
    storage.clearRetainingCapacity();

    const file_words = file.readEn(temp_arena.allocator());
    std.debug.print("LOAD storage:...file_word[{d}]\n", .{file_words.items.len});
    nword: for (file_words.items) |w| {
        if (!hasStorWord(storage.items, w)) {
            var i: u32 = 0;
            while (i < w.len) {
                const n = std.unicode.utf8ByteSequenceLength(w[i]) catch {
                    std.debug.print("exception for w[i]: {s}[{d}]\n", .{ w[i .. i + 1], w[i] });
                    std.debug.print("for word {s}", .{w});
                    return;
                };
                var c: u21 = @intCast(w[i]);
                if (i + n <= w.len and std.unicode.utf8ValidateSlice(w[i .. i + n])) {
                    c = std.unicode.utf8Decode(w[i .. i + n]) catch unreachable;
                }
                switch (c) {
                    8208,
                    9889,
                    128034,
                    228,
                    177,
                    960,
                    934,
                    964,
                    9500,
                    9472,
                    9474,
                    9492,
                    9658,
                    9829,
                    246,
                    223,
                    8722,
                    8971,
                    8712,
                    8805,
                    8804,
                    8730,
                    8211,
                    261,
                    8217,
                    8658,
                    181,
                    923,
                    592,
                    955,
                    11375,
                    => continue :nword,
                    else => {},
                }
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
            var word = word_arena.allocator().alloc(u8, w.len) catch unreachable;
            @memcpy(word[0..], w);
            storage.append(.{ .word = word[0..] }) catch unreachable;
        }
    }
    std.debug.print("word number: {d}/{d}\n", .{ storage.items.len, file_words.items.len });
    std.debug.print("Symbols:\n", .{});
    for (symbols.items, 0..) |s, i| {
        var str = symbol_all.allocator().alloc(u8, 4) catch unreachable;
        defer symbol_all.allocator().free(str);
        const n = std.unicode.utf8CodepointSequenceLength(s) catch unreachable;
        _ = std.unicode.utf8Encode(s, str[0..]) catch unreachable;
        const arr = str[0..n];
        std.debug.print("\t{d}. {s} {d}[{any}]\n", .{ i, str, s, arr });
    }
}

pub fn createAndInitExcercise(state: *State) void {
    const time = std.time.milliTimestamp();
    defer _ = temp_arena.reset(.free_all);
    var words: std.ArrayList([]u8) = std.ArrayList([]u8).init(temp_arena.allocator());

    calculateScore(storage.items, state.*);
    std.debug.print("\t calculate score: {d}\n", .{std.time.milliTimestamp() - time});
    var r = std.Random.DefaultPrng.init(@intCast(std.time.microTimestamp()));
    r.random().shuffle(StorWord, storage.items);
    std.debug.print("\t shuffle: {d}\n", .{std.time.milliTimestamp() - time});
    std.mem.sort(StorWord, storage.items, .{}, lessThanSW);
    std.debug.print("\t sort: {d}\n", .{std.time.milliTimestamp() - time});
    std.debug.print("Top 10 sorted words with score\n", .{});
    for (storage.items, 0..) |sw, i| {
        if (i > 10) break;
        if (sw.score > 0) {
            const c = @divFloor(60 * 1000 * 1000 * 1000, sw.score);
            std.debug.print("\t{d}: {s} in {d}\n", .{ i, sw.word, c });
        }
    }
    const time_post = std.time.milliTimestamp();
    std.debug.print("time 1: {d}\n", .{time_post - time});

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

    std.debug.print("time 2: {d}\n", .{std.time.milliTimestamp() - time_post});
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
