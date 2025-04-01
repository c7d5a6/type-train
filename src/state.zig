const std = @import("std");
const cnst = @import("constants.zig");

var typed_buff_arr: [cnst.max_characters_test]u8 = undefined;
var typed_buff = std.heap.FixedBufferAllocator.init(&typed_buff_arr);
const lorem = "lorem ipsum dolor sit amet consectetur adipiscing elit pellentesque rutrum tristique tellus luctus cursus cras sagittis magna mi vel ultricies felis rutrum ac donec nisl";

pub const State = struct {
    exercise: []const u8 = lorem[0..],
    typed: std.ArrayList(u8),
    pub fn init() State {
        return .{ .typed = std.ArrayList(u8).initCapacity(typed_buff.allocator(), typed_buff_arr.len) catch unreachable };
    }
};
