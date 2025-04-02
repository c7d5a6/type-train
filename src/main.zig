const std = @import("std");
const rl = @import("raylib");
const constants = @import("constants.zig");
const State = @import("state.zig").State;
const TextDrawer = @import("text-drawer.zig").TextDrawer;
const key_updater = @import("key_press_updater.zig");

const srn_width = 800;
const srn_height = 450;

pub fn main() anyerror!void {
    var state = State.init();
    // Initialization
    //--------------------------------------------------------------------------------------
    rl.setConfigFlags(rl.ConfigFlags{
        .vsync_hint = true,
        .window_resizable = true,
        .msaa_4x_hint = false,
        // .window_highdpi = true,
    });

    rl.initWindow(srn_width, srn_height, "TypeTrain");
    defer rl.closeWindow();

    rl.setTargetFPS(0);
    //
    const text_drawer = TextDrawer.init(&state);
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // const time = std.time.nanoTimestamp();
        key_updater.processPressed(&state);
        // std.debug.print("update time {d}\n", .{std.time.nanoTimestamp() - time});
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        // const drawtime = std.time.nanoTimestamp();
        defer rl.endDrawing();

        rl.enableEventWaiting();

        rl.clearBackground(constants.background_color);

        text_drawer.drawText();

        // rl.drawTextEx(font, "Привет новое окно", .{ .x = 80, .y = 80 }, font_size, 1, constants.text_color);
        rl.drawFPS(0, 0);
        // std.debug.print("draw time {d}\n", .{std.time.nanoTimestamp() - drawtime});
        // std.debug.print("frame time {d}\n", .{std.time.nanoTimestamp() - time});

        //----------------------------------------------------------------------------------
    }
}
