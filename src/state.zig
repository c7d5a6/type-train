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
    ex_id: ?u8 = null,
    key_time: ?i128 = null,

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
        self.ex_id = null;
    }
};
