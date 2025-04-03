const std = @import("std");
const rl = @import("raylib");
const State = @import("state.zig").State;
const TypedState = @import("common_enums.zig").TypedState;
const unicode = std.unicode;

pub fn processPressed(state: *State) void {
    var k: u8 = 0;
    var ch: i32 = rl.getCharPressed();
    var new_time: ?i128 = if (ch == 0) null else std.time.nanoTimestamp();
    const prev_key_time = state.prev_key_time;

    while (ch != 0) {
        if (k != 0) {
            new_time = null;
        }
        const key_time = if (new_time == null or prev_key_time == null) null else new_time.? - prev_key_time.?;
        const ts = typeCh(state, @intCast(ch));
        state.addTyped(ts, key_time);

        ch = rl.getCharPressed();
        state.prev_key_time = new_time;
        k += 1;
    }

    if (rl.isKeyPressed(.backspace)) {
        removeCh(state);
        new_time = null;
    }
    state.key_time = if (new_time) |nt| if (prev_key_time) |st| nt - st else state.key_time else state.key_time;
}

fn typeCh(state: *State, ch: u21) TypedState {
    state.typed.append(ch) catch unreachable;

    const eid: i16 = state.ex_id orelse -1;
    if (eid + 1 >= state.exercise.len) {
        return .wrong_over;
    }

    const en = state.exercise[@intCast(eid + 1)];

    if (ch == ' ' and en != ' ') {
        var i: u8 = @intCast(eid + 1);
        while (i < state.exercise.len and state.exercise[i] != ' ') {
            i += 1;
        }
        state.ex_id = i;
        return .wrong_over;
    }

    if (ch != ' ' and en == ' ') {
        return .wrong_over;
    }
    state.ex_id = @intCast(eid + 1);
    if (en != ch) {
        return .{ .wrong = @intCast(eid + 1) };
    }
    if (en == ' ' and ch == ' ') {
        return .whitespace;
    }
    return .{ .correct = @intCast(eid + 1) };
}

fn removeCh(state: *State) void {
    if (state.typed.items.len == 0) return;
    _ = state.typed.swapRemove(state.typed.items.len - 1);

    var ie: u8 = 0;
    var it: u8 = 0;
    while (it < state.typed.items.len) {
        if (state.exercise.len <= ie or
            (state.exercise[ie] == ' ' and
                state.typed.items[it] != ' '))
        {
            it += 1;
        } else if (state.typed.items.len <= it or
            (state.typed.items[it] == ' ' and
                state.exercise[ie] != ' '))
        {
            ie += 1;
        } else {
            ie += 1;
            it += 1;
        }
    }
    state.ex_id = if (ie == 0) null else ie - 1;
}
