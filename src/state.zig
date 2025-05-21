const std = @import("std");
const assert = std.debug.assert;
const cnst = @import("constants.zig");
const TypedState = @import("common_enums.zig").TypedState;
const unicode = std.unicode;

var exer_buff_arr: [cnst.max_characters_test * 8]u8 = undefined;
var exer_buff = std.heap.FixedBufferAllocator.init(&exer_buff_arr);
var typed_buff_arr: [cnst.max_characters_test * 8]u8 = undefined;
var typed_buff = std.heap.FixedBufferAllocator.init(&typed_buff_arr);

var typed_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var symbol_stats_da = std.heap.DebugAllocator(.{}).init;
var symbol_stats_allocator = symbol_stats_da.allocator();

const StateType = enum {
    load,
    exercise_init,
    exercise,
    exercise_finalyze,
    stats,
};
const TypedSymbol = struct {
    smb: [:0]u8,
    time: ?i128,
    err: bool,
};

pub const SymbolStat = struct {
    smb: [:0]u8,
    sum_time: ?i128,
    n_time: u32,
    n_error: u32,
    n: u32,
};

pub const State = struct {
    state: StateType = .exercise_init,
    exercise_len: u8 = 10,
    exercise: std.ArrayList(u21),
    typed: std.ArrayList(u21),
    ex_id: ?u8 = null,
    key_time: ?i128 = null,
    prev_key_time: ?i128 = null,
    typed_symbols: std.ArrayList(TypedSymbol),
    symbol_stats: std.ArrayList(SymbolStat),
    cpm: u64 = 0,

    pub fn init(state: StateType) State {
        return State{
            .state = state,
            .exercise = std.ArrayList(u21).initCapacity(exer_buff.allocator(), cnst.max_characters_test) catch unreachable,
            .typed = std.ArrayList(u21).initCapacity(typed_buff.allocator(), cnst.max_characters_test) catch unreachable,
            .typed_symbols = std.ArrayList(TypedSymbol).init(typed_arena.allocator()),
            .symbol_stats = std.ArrayList(SymbolStat).init(symbol_stats_allocator),
        };
        // return res;
    }

    pub fn init_exercise(self: *State, words: []const []const u8, symbols: []const u21) void {
        std.debug.assert(self.state == .exercise_init);

        self.resetTyped();
        self.exercise.clearRetainingCapacity();

        for (words, 0..) |word, iw| {
            var i: u32 = 0;
            if (iw != 0)
                self.exercise.append(' ') catch unreachable;
            while (i < word.len) {
                const len = std.unicode.utf8ByteSequenceLength(word[i]) catch unreachable;
                const ch = std.unicode.utf8Decode(word[i .. i + len]) catch unreachable;
                self.exercise.append(ch) catch unreachable;

                i += @intCast(len);
            }
        }

        next: for (symbols) |s| {
            const len = std.unicode.utf8CodepointSequenceLength(s) catch unreachable;
            var smb = symbol_stats_allocator.allocSentinel(u8, len, 0) catch unreachable;
            const n = std.unicode.utf8Encode(s, smb[0..]) catch unreachable;
            std.debug.assert(len == n);
            for (self.symbol_stats.items) |ss| {
                if (ss.smb.len == n and std.mem.eql(u8, ss.smb, smb)) {
                    symbol_stats_allocator.free(smb);
                    continue :next;
                }
            }
            const ss = SymbolStat{
                .smb = smb,
                .n = 0,
                .n_time = 0,
                .n_error = 0,
                .sum_time = null,
            };
            self.symbol_stats.append(ss) catch unreachable;
        }

        self.sortStats();

        self.state = .exercise;
    }

    pub fn resetTyped(self: *State) void {
        _ = self.typed.clearRetainingCapacity();
        self.ex_id = null;
        _ = typed_arena.reset(.retain_capacity);
        self.typed_symbols = std.ArrayList(TypedSymbol).init(typed_arena.allocator());
    }

    pub fn addTyped(self: *State, ts: TypedState, key_time: ?i128) void {
        assert(self.state == .exercise);

        if (ts == .wrong_over or ts == .whitespace) {
            return;
        }
        const ei = switch (ts) {
            .wrong, .correct => |i| i,
            else => unreachable,
        };
        const time = if (ts != .correct)
            null
        else if (key_time != null and key_time.? < 1000 * 1000 * 1000 * 2)
            key_time
        else
            null;

        lbl: switch (@as(i4, 1)) {
            1 => {
                self.addTypedSymbols(self.exercise.items[ei .. ei + 1], time, ts == .wrong);
                continue :lbl 2;
            },
            2 => {
                if (ei == 0) continue :lbl -1;
                if (self.exercise.items[ei - 1] == ' ') continue :lbl -1;
                self.addTypedSymbols(self.exercise.items[ei - 1 .. ei + 1], time, ts == .wrong);
                continue :lbl 3;
            },
            3 => {
                if (ei == 1) continue :lbl -1;
                if (self.exercise.items[ei - 2] == ' ') continue :lbl 4;
                self.addTypedSymbols(self.exercise.items[ei - 2 .. ei + 1], time, ts == .wrong);
                continue :lbl 4;
            },
            4 => {
                if (ei == 0) continue :lbl -1;
                if (ei + 1 >= self.exercise.items.len) continue :lbl -1;
                if (self.exercise.items[ei - 1] == ' ') continue :lbl -1;
                if (self.exercise.items[ei + 1] == ' ') continue :lbl -1;
                self.addTypedSymbols(self.exercise.items[ei - 1 .. ei + 2], time, ts == .wrong);
                continue :lbl -1;
            },
            else => {},
        }
    }

    fn addTypedSymbols(self: *State, symbols: []const u21, time: ?i128, is_error: bool) void {
        assert(self.state == .exercise);
        const a = typed_arena.allocator();
        var str = std.ArrayList(u8).initCapacity(a, 4 * 3) catch unreachable;
        var buff: [4]u8 = undefined;
        for (symbols) |s| {
            const n = unicode.utf8Encode(s, buff[0..]) catch unreachable;
            str.appendSlice(buff[0..n]) catch unreachable;
        }
        var smb = a.allocSentinel(u8, str.items.len, 0) catch unreachable;
        @memcpy(smb[0..], str.items);
        self.typed_symbols.append(.{
            .smb = smb,
            .time = time,
            .err = is_error,
        }) catch unreachable;
    }

    pub fn finalyzeStats(self: *State) void {
        assert(self.state == .exercise);
        self.state = .exercise_finalyze;
        std.debug.print("finalyze stats\n", .{});

        std.debug.print("typed symbols stats lengs {}\n", .{self.typed_symbols.items.len});
        next: for (self.typed_symbols.items) |ts| {
            for (self.symbol_stats.items, 0..) |s, i| {
                if (std.mem.eql(u8, ts.smb, s.smb)) {
                    fillSymbolStat(&self.symbol_stats.items[i], ts);
                    continue :next;
                }
            }
            var smb = symbol_stats_allocator.allocSentinel(u8, ts.smb.len, 0) catch unreachable;
            @memcpy(smb[0..], ts.smb);

            var s = SymbolStat{
                .smb = smb,
                .n = 0,
                .n_time = 0,
                .n_error = 0,
                .sum_time = null,
            };
            fillSymbolStat(&s, ts);
            self.symbol_stats.append(s) catch unreachable;
        }
        self.sortStats();

        var n: u128 = 0;
        var t: u128 = 0;
        for (self.symbol_stats.items) |s| {
            if (std.unicode.utf8ByteSequenceLength(s.smb[0]) catch unreachable == s.smb.len and s.n_time > 0) {
                n += s.n_time;
                t += @intCast(s.sum_time orelse 0);
            }
        }
        if (t != 0)
            self.cpm = @intCast(@divFloor(60 * 1000 * 1000 * 1000 * n, t));

        self.state = .exercise_init;
    }

    pub fn sortStats(self: *State) void {
        std.mem.sort(SymbolStat, self.symbol_stats.items, .{}, smbStLessThan);
    }
};

fn fillSymbolStat(stat: *SymbolStat, ts: TypedSymbol) void {
    stat.n += 1;
    if (ts.time) |time| {
        stat.sum_time = (stat.sum_time orelse 0) + time;
        stat.n_time += 1;
    }
    if (ts.err)
        stat.n_error += 1;
}

fn smbStLessThan(v: @TypeOf(.{}), lhs: SymbolStat, rhs: SymbolStat) bool {
    _ = v;
    const el: u64 = if (lhs.n == 0) 0 else @divFloor((lhs.n_error * 100), lhs.n);
    const er: u64 = if (rhs.n == 0) 0 else @divFloor((rhs.n_error * 100), rhs.n);
    const l1smb = std.unicode.utf8ByteSequenceLength(lhs.smb[0]) catch unreachable == lhs.smb.len;
    const r1smb = std.unicode.utf8ByteSequenceLength(lhs.smb[0]) catch unreachable == rhs.smb.len;
    if ((l1smb and lhs.n < 3) or
        (r1smb and rhs.n < 3))
    {
        return lhs.n < rhs.n;
    }
    if (el == er) {
        if (lhs.sum_time == null and rhs.sum_time == null) return false;
        if (lhs.sum_time) |l_time|
            if (rhs.sum_time) |r_time| {
                return l_time * rhs.n_time > r_time * lhs.n_time;
            } else return false
        else
            return true;
    }
    return el > er;
}
