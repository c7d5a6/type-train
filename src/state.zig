const std = @import("std");
const cnst = @import("constants.zig");
const TypedState = @import("common_enums.zig").TypedState;
const unicode = std.unicode;

var typed_buff_arr: [cnst.max_characters_test * 8]u8 = undefined;
var typed_buff = std.heap.FixedBufferAllocator.init(&typed_buff_arr);
const lorem = "lorem ipsum dolor sit amet consectetur adipiscing elit pellentesque rutrum tristique tellus luctus cursus cras sagittis magna mi vel ultricies felis rutrum ac donec nisl";

var typed_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

pub const State = struct {
    exercise: [lorem.len]u21,
    typed: std.ArrayList(u21),
    ex_id: ?u8 = null,
    key_time: ?i128 = null,
    prev_key_time: ?i128 = null,
    typed_symbols: std.ArrayList(TypedSymbol),

    pub fn init() State {
        var exersise: [lorem.len]u21 = undefined;

        for (lorem, 0..) |ch, i| {
            exersise[i] = unicode.utf8Decode(&[_]u8{ch}) catch unreachable;
        }

        return .{
            .exercise = exersise,
            .typed = std.ArrayList(u21).initCapacity(typed_buff.allocator(), cnst.max_characters_test) catch unreachable,
            .typed_symbols = std.ArrayList(TypedSymbol).init(typed_arena.allocator()),
        };
    }

    pub fn resetTyped(self: *State) void {
        self.typed.clearRetainingCapacity();
        self.ex_id = null;
        typed_arena.reset(.retain_capacity);
        self.typed_symbols = std.ArrayList(TypedSymbol).init(typed_arena.allocator());
    }

    pub fn addTyped(self: *State, ts: TypedState, key_time: ?i128) void {
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
        std.debug.print("current smbls {any}", .{self.typed_symbols.items});
    }
};

const TypedSymbol = struct {
    smb: [:0]u8,
    time: ?i128,
    err: bool,
};
