const std = @import("std");
const rl = @import("raylib");
const constants = @import("constants.zig");
const State = @import("state.zig").State;
const TextDrawer = @import("text-drawer.zig").TextDrawer;
const key_updater = @import("key_press_updater.zig");
const fileReader = @import("file-reader.zig");

const srn_width = 800;
const srn_height = 450;

fn drawFinalStats(state: State) void {
    var start = rl.Vector2{ .x = 100, .y = 100 };
    std.debug.print("symbol stats lengs {}\n", .{state.symbol_stats.items.len});
    for (state.symbol_stats.items) |st| {
        const st_text = std.fmt.allocPrintZ(std.heap.c_allocator, "{s}: cpm {?} with {d} errors", .{
            st.smb,
            if (st.sum_time) |time|
                @divFloor(60 * 1000 * 1000 * 1000 * @as(i128, st.n_time), time)
            else
                null,
            st.n_error,
        }) catch unreachable;
        rl.drawText(st_text, @intFromFloat(start.x), @intFromFloat(start.y), 32, rl.Color.yellow);
        start = start.add(.{ .x = 0, .y = 33 });
    }
}

pub fn main() anyerror!void {
    fileReader.readEn();
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

        switch (state.state) {
            .exercise => text_drawer.drawText(),
            .exercise_finalyze => drawFinalStats(state),
            else => {},
        }

        // rl.drawTextEx(font, "Привет новое окно", .{ .x = 80, .y = 80 }, font_size, 1, constants.text_color);
        rl.drawFPS(0, 0);
        // std.debug.print("draw time {d}\n", .{std.time.nanoTimestamp() - drawtime});
        // std.debug.print("frame time {d}\n", .{std.time.nanoTimestamp() - time});

        //----------------------------------------------------------------------------------
    }
}
