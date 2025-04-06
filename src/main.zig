const std = @import("std");
const rl = @import("raylib");
const constants = @import("constants.zig");
const State = @import("state.zig").State;
const Drawer = @import("drawer/drawer.zig").Drawer;
const key_updater = @import("key_press_updater.zig");
const word_storage = @import("word_storage.zig");

const srn_width = 800;
const srn_height = 450;

pub fn main() anyerror!void {
    word_storage.load();
    var state = State.init();
    word_storage.createExcercise(&state);
    rl.setTraceLogLevel(.warning);
    // Initialization
    //--------------------------------------------------------------------------------------
    rl.setConfigFlags(rl.ConfigFlags{
        .vsync_hint = false,
        .window_resizable = true,
        .msaa_4x_hint = true,
        .window_highdpi = true,
    });

    rl.initWindow(srn_width, srn_height, "TypeTrain");
    defer rl.closeWindow();

    rl.setTargetFPS(0);
    //
    const drawer = Drawer.init(&state);
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        key_updater.processPressed(&state);
        if (state.ex_id orelse 0 >= state.exercise.items.len - 1 and state.state == .exercise) {
            std.debug.print("FYNILIZE STATS", .{});
            state.finalyzeStats();
        }
        if (state.state == .exercise_init) {
            word_storage.createExcercise(&state);
        }
        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        drawer.draw();
    }
}
