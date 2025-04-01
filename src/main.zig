const rl = @import("raylib");
const constants = @import("constants.zig");
const State = @import("state.zig").State;
const std = @import("std");
const TextDrawer = @import("text-drawer.zig").TextDrawer;
const unicode = std.unicode;

const font_size = 40;
const initial_text = "";

var bufferArr: [1000]u8 = undefined;
var buffer = std.heap.FixedBufferAllocator.init(&bufferArr);
var aa = std.heap.ArenaAllocator.init(buffer.allocator());

fn printTime(name: []const u8, time: i128) void {
    const seconds = @divFloor(time, 1_000_000_000);
    const milliseconds = @divFloor(@mod(time, 1_000_000_000), 1_000_000);
    const microseconds = @divFloor(@mod(time, 1_000_000), 1_000);
    const nanoseconds = @mod(time, 1_000);
    std.debug.print("{s} time: {}s {}.{}.{}\n", .{ name, seconds, milliseconds, microseconds, nanoseconds });
}

fn processPressed(pt: i128, state: *State) i128 {
    defer _ = aa.reset(.retain_capacity);
    var ch = rl.getCharPressed();
    var prevTime = pt;
    var k: u8 = 1;
    while (ch != 0) {
        var s: [4]u8 = undefined;
        _ = unicode.utf8Encode(@intCast(ch), &s) catch unreachable;
        state.typed.append(@intCast(ch)) catch unreachable;
        const newTime = std.time.nanoTimestamp();
        const lbl = std.fmt.allocPrint(aa.allocator(), "Pressed {s} in loop {d}", .{ s, k }) catch unreachable;
        printTime(lbl, newTime - prevTime);
        prevTime = newTime;
        ch = rl.getCharPressed();
        k += 1;
    }
    if (rl.isKeyPressed(.backspace)) {
        _ = state.typed.swapRemove(state.typed.items.len - 1);
    }
    return prevTime;
}
const srn_width = 800;
const srn_height = 450;

pub fn main() anyerror!void {
    var state = State.init();
    var da = std.heap.DebugAllocator(.{}){};
    var aaa = std.heap.ArenaAllocator.init(da.allocator());
    defer aaa.deinit();
    const all = aaa.allocator();
    var text = std.ArrayList(u8).init(all);
    defer text.deinit();
    // Initialization
    //--------------------------------------------------------------------------------------
    rl.setConfigFlags(rl.ConfigFlags{
        .vsync_hint = true,
        .window_resizable = true,
        .msaa_4x_hint = false,
        // .window_highdpi = true,
    });

    rl.initWindow(srn_width, srn_height, "TypeTrain");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(0); // Set our game to run at 60 frames-per-second
    //
    const text_drawer = TextDrawer.init(&state);
    //--------------------------------------------------------------------------------------
    var prevTime = std.time.nanoTimestamp();

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // const loopStart = std.time.nanoTimestamp();
        prevTime = processPressed(prevTime, &state);
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.enableEventWaiting();

        rl.clearBackground(constants.background_color);

        text_drawer.drawText();

        // rl.drawTextEx(font, "Привет новое окно", .{ .x = 80, .y = 80 }, font_size, 1, constants.text_color);
        rl.drawFPS(0, 0);

        //----------------------------------------------------------------------------------
    }
}
