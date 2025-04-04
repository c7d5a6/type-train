const std = @import("std");
const assert = std.debug.assert;
const cnst = @import("constants.zig");
const TypedState = @import("common_enums.zig").TypedState;
const unicode = std.unicode;

var typed_buff_arr: [cnst.max_characters_test * 8]u8 = undefined;
var typed_buff = std.heap.FixedBufferAllocator.init(&typed_buff_arr);
const lorem = "lorem ipsum dolor sit amet consectetur adipiscing elit pellentesque rutrum tristique tellus luctus cursus cras sagittis magna mi vel ultricies felis rutrum ac donec nisl";

var typed_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var symbol_stats_da = std.heap.DebugAllocator(.{}).init;
var symbol_stats_allocator = symbol_stats_da.allocator();

const StateType = enum {
    exercise,
    exercise_finalyze,
    exercise_stats,
};
const TypedSymbol = struct {
    smb: [:0]u8,
    time: ?i128,
    err: bool,
};

const SymbolStat = struct {
    smb: [:0]u8,
    sum_time: ?i128,
    n_time: u32,
    n_error: u32,
    n: u32,
};

pub const State = struct {
    state: StateType = .exercise,
    exercise: [lorem.len]u21,
    typed: std.ArrayList(u21),
    ex_id: ?u8 = null,
    key_time: ?i128 = null,
    prev_key_time: ?i128 = null,
    typed_symbols: std.ArrayList(TypedSymbol),
    symbol_stats: std.ArrayList(SymbolStat),

    pub fn init() State {
        var exersise: [lorem.len]u21 = undefined;

        for (lorem, 0..) |ch, i| {
            exersise[i] = unicode.utf8Decode(&[_]u8{ch}) catch unreachable;
        }

        return .{
            .exercise = exersise,
            .typed = std.ArrayList(u21).initCapacity(typed_buff.allocator(), cnst.max_characters_test) catch unreachable,
            .typed_symbols = std.ArrayList(TypedSymbol).init(typed_arena.allocator()),
            .symbol_stats = std.ArrayList(SymbolStat).init(symbol_stats_allocator),
        };
    }

    pub fn resetTyped(self: *State) void {
        // TODO: assert state state
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
                self.addTypedSymbols(self.exercise[ei .. ei + 1], time, ts == .wrong);
                continue :lbl 2;
            },
            2 => {
                if (ei == 0) continue :lbl -1;
                if (self.exercise[ei - 1] == ' ') continue :lbl -1;
                self.addTypedSymbols(self.exercise[ei - 1 .. ei + 1], time, ts == .wrong);
                continue :lbl 3;
            },
            3 => {
                if (ei == 1) continue :lbl -1;
                if (self.exercise[ei - 2] == ' ') continue :lbl 4;
                self.addTypedSymbols(self.exercise[ei - 2 .. ei + 1], time, ts == .wrong);
                continue :lbl 4;
            },
            4 => {
                if (ei == 0) continue :lbl -1;
                if (self.exercise[ei - 1] == ' ') continue :lbl -1;
                if (self.exercise[ei + 1] == ' ') continue :lbl -1;
                if (ei >= self.exercise.len) continue :lbl -1;
                self.addTypedSymbols(self.exercise[ei - 1 .. ei + 2], time, ts == .wrong);
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
        assert(self.state == .exercise_finalyze);
        // _ = symbol_arena.reset(.retain_capacity);
        // self.symbol_stats = std.ArrayList(SymbolStat).initCapacity(
        //     symbol_arena.allocator(),
        //     self.typed_symbols.items.len,
        // ) catch unreachable;

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
            std.mem.sort(SymbolStat, self.symbol_stats.items, .{}, smbStLessThan);
        }
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
    const e1n2 = lhs.n_error * rhs.n;
    const e2n1 = rhs.n_error * lhs.n;
    if (e1n2 == e2n1) {
        if (lhs.sum_time == null and rhs.sum_time == null) return false;
        if (lhs.sum_time) |l_time|
            if (rhs.sum_time) |r_time|
                return l_time * rhs.n_time > r_time * lhs.n_time
            else
                return false
        else
            return true;
    }
    return e1n2 > e2n1;
}
