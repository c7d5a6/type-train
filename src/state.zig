const std = @import("std");
const cnst = @import("constants.zig");
const CharState = @import("common_enums.zig").CharState;
const charState = @import("common_enums.zig").charState;
const unicode = std.unicode;

var typed_buff_arr: [cnst.max_characters_test * 8]u8 = undefined;
var typed_buff = std.heap.FixedBufferAllocator.init(&typed_buff_arr);
const lorem = "lorem ipsum dolor sit amet consectetur adipiscing elit pellentesque rutrum tristique tellus luctus cursus cras sagittis magna mi vel ultricies felis rutrum ac donec nisl";

pub const State = struct {
    exercise: [lorem.len]u21,
    typed: std.ArrayList(u21),
    ex_id: u8 = 0,
    input_state: CharState = .not_typed,

    pub fn init() State {
        var exersise: [lorem.len]u21 = undefined;

        for (lorem, 0..) |ch, i| {
            exersise[i] = unicode.utf8Decode(&[_]u8{ch}) catch unreachable;
        }

        return .{
            .exercise = exersise,
            .typed = std.ArrayList(u21).initCapacity(typed_buff.allocator(), cnst.max_characters_test) catch unreachable,
        };
    }

    pub fn resetTyped(self: *State) void {
        self.typed.clearRetainingCapacity();
        self.ex_id = 0;
        self.input_state = .not_typed;
    }

    pub fn typeCh(self: *State, ch: u21) void {
        self.typed.append(ch) catch unreachable;
        const ti: u8 = @intCast(self.typed.items.len);

        const ch_state: CharState = charState(
            &self.exercise,
            self.typed.items,
            self.ex_id,
            ti - 1,
        );
        switch (ch_state) {
            .not_typed, .correct, .wrong => {
                self.ex_id += 1;
            },
            else => {},
        }

        self.input_state = ch_state;

        std.debug.print(
            "{} with\n\t ex#[{d}]\n\t tp#[{d}]\n",
            .{ self.input_state, self.ex_id, ti },
        );
    }

    pub fn removeCh(self: *State) void {
        _ = self.typed.swapRemove(self.typed.items.len - 1);
        const ti: u8 = @intCast(self.typed.items.len);
        switch (self.input_state) {
            .not_typed, .correct, .wrong => {
                self.ex_id -= 1;
            },
            else => {},
        }
        self.input_state = charState(
            &self.exercise,
            self.typed.items,
            self.ex_id,
            ti,
        );
        std.debug.print(
            "{} with\n\t ex#[{d}]\n\t tp#[{d}] of {d}\n",
            .{ self.input_state, self.ex_id, ti, ti },
        );
    }
};
