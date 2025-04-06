const std = @import("std");
const rl = @import("raylib");
const constants = @import("constants.zig");
const State = @import("state.zig").State;
const Drawer = @import("drawer/drawer.zig").Drawer;
const key_updater = @import("key_press_updater.zig");
const word_storage = @import("word_storage.zig");
const state_processor = @import("state-processor.zig");

const srn_width = 800;
const srn_height = 450;

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    rl.setTraceLogLevel(.warning);
    rl.setConfigFlags(rl.ConfigFlags{
        .vsync_hint = false,
        .window_resizable = true,
        .msaa_4x_hint = true,
        // .window_highdpi = true,
    });

    rl.initWindow(srn_width, srn_height, "TypeTrain");
    defer rl.closeWindow();

    var state = State.init(.load);
    const drawer = Drawer.init(&state);
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        state_processor.processState(&state);
        key_updater.processPressed(&state);
        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        drawer.draw();
    }
}
