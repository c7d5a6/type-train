const std = @import("std");
const rl = @import("raylib");
const State = @import("state.zig").State;
const unicode = std.unicode;

fn printTime(name: []const u8, time: i128) void {
    const seconds = @divFloor(time, 1_000_000_000);
    const milliseconds = @divFloor(@mod(time, 1_000_000_000), 1_000_000);
    const microseconds = @divFloor(@mod(time, 1_000_000), 1_000);
    const nanoseconds = @mod(time, 1_000);
    std.debug.print("{s} time: {}s {}.{}.{}\n", .{ name, seconds, milliseconds, microseconds, nanoseconds });
}

pub fn processPressed(state: *State) void {
    var new_time: ?i128 = std.time.nanoTimestamp();
    // const prev_time = state.key_time;
    var k: u8 = 0;
    var ch: i32 = rl.getCharPressed();
    while (ch != 0) {
        const ts = typeCh(state, @intCast(ch));
        std.debug.print("eixaf {any}\n", .{state.ex_id});
        std.debug.print("Ts {any}\n", .{ts});

        if (k == 0) {}

        ch = rl.getCharPressed();
        k += 1;
    }
    if (rl.isKeyPressed(.backspace)) {
        removeCh(state);
        new_time = null;
    }
    state.key_time = new_time;
}

const TypedStateType = enum {
    correct,
    wrong,
    wrong_over,
    whitespace,
};
const TypedState = union(TypedStateType) {
    correct: u21,
    wrong: u21,
    wrong_over: void,
    whitespace: void,
};

fn typeCh(state: *State, ch: u21) TypedState {
    state.typed.append(ch) catch unreachable;
    std.debug.print("eix {any}\n", .{state.ex_id});
    if (state.ex_id) |i| {
        if (i >= state.exercise.len) {
            return .wrong_over;
        }
    }
    if (ch == ' ') {
        state.ex_id = state.ex_id orelse 0;
        while (state.ex_id.? < state.exercise.len and state.exercise[state.ex_id.?] != ' ')
            state.ex_id.? += 1;
        return .whitespace;
    } else {
        if (state.ex_id) |i| {
            if (state.exercise[i] == ' ') {
                return .wrong_over;
            }
        }
    }
    state.ex_id = (state.ex_id orelse 0) + 1;
    if (state.ex_id.? >= state.exercise.len) {
        return .wrong_over;
    }
    const ech = state.exercise[state.ex_id.?];
    if (ech == ' ') {
        return .wrong_over;
    }
    if (ech != ch) {
        return .{ .wrong = ech };
    }
    return .{ .correct = ech };
}

fn removeCh(state: *State) void {
    _ = state.typed.swapRemove(state.typed.items.len - 1);
}
