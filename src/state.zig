const std = @import("std");

var wrd_buff_arr: [1000]u8 = undefined;
var wrd_buffer = std.heap.FixedBufferAllocator.init(&wrd_buff_arr);
const lorem = "lorem ipsum dolor sit amet consectetur adipiscing elit pellentesque rutrum tristique tellus luctus cursus cras sagittis magna mi vel ultricies felis rutrum ac donec nisl";

pub const State = struct {
    exercise: []const u8 = lorem[0..],
    typed: std.ArrayList(u8),
    pub fn init() State {
        return .{ .typed = std.ArrayList(u8).init(std.heap.c_allocator) };
    }
};
