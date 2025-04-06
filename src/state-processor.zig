const std = @import("std");
const State = @import("state.zig").State;
const word_storage = @import("word_storage.zig");

pub fn processState(state: *State) void {
    switch (state.state) {
        .load => {
            word_storage.load();
            state.state = .exercise_init;
        },
        .exercise_init => word_storage.createAndInitExcercise(state),
        .exercise => {
            if (state.ex_id orelse 0 >= state.exercise.items.len - 1) {
                std.debug.print("FYNILIZE STATS", .{});
                state.finalyzeStats();
            }
        },
        .exercise_finalyze => {
            state.finalyzeStats();
        },
        else => {},
    }
}
