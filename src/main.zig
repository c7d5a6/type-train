const rl = @import("raylib");
const constants = @import("constants.zig");
const State = @import("state.zig").State;
const std = @import("std");
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
        const n = unicode.utf8Encode(@intCast(ch), &s) catch unreachable;
        state.typed.appendSlice(s[0..n]) catch unreachable;
        const newTime = std.time.nanoTimestamp();
        const lbl = std.fmt.allocPrint(aa.allocator(), "Pressed {s} in loop {d}", .{ s, k }) catch unreachable;
        printTime(lbl, newTime - prevTime);
        prevTime = newTime;
        ch = rl.getCharPressed();
        k += 1;
    }
    return prevTime;
}
const text_margin = 100;
fn drawText(font: rl.Font, state: State) void {
    const b_size = rl.measureTextEx(font, "a bc", font_size, 1).divide(.{ .x = 4, .y = 1 });
    const text_width = @min(rl.getRenderWidth() - text_margin * 2, 800);
    const max_width: i32 = @intFromFloat(@as(f32, @floatFromInt(text_width)) / b_size.x);
    const start = rl.Vector2{ .x = @as(f32, @floatFromInt(rl.getRenderWidth() - text_width)) / 2, .y = 200 };
    const ex_text = state.exercise;
    var line: f32 = 1;
    var i: u8 = 0;
    var j: u8 = 0;
    var t_idx: u8 = 0;
    while (ex_text.len > j) {
        if (ex_text[j] == ' ') {
            const width = j - i;
            if (width >= max_width) {
                while (j < ex_text.len and ex_text[j] == ' ') j += 1;
                t_idx = drawLine(font, start.add(.{ .x = 0, .y = line * b_size.y }), ex_text[i..j], state, t_idx);
                i = j;
                line += 1;
            }
        }
        j += 1;
    }
    if (i < ex_text.len) {
        _ = drawLine(font, start.add(.{ .x = 0, .y = line * b_size.y }), ex_text[i..j], state, t_idx);
    }
}

fn drawLine(font: rl.Font, line_start: rl.Vector2, text: []const u8, state: State, t_idx: u8) u8 {
    const typed = state.typed.items;
    var i: u8 = 0;
    var ti: u8 = t_idx;
    var point = rl.measureTextEx(font, "", font_size, 1);
    while (i < text.len) {
        var j: u8 = 0;
        while (typed.len > ti + j and text[i + j] == typed[ti + j]) {
            j += 1;
        }
        if (j > 0) {
            const t = std.mem.Allocator.dupeZ(std.heap.c_allocator, u8, text[i .. i + j]) catch unreachable;
            rl.drawTextEx(font, t, line_start.add(.{ .x = point.x, .y = 0 }), font_size, 1, constants.text_color);
            point = point.add(rl.measureTextEx(font, t, font_size, 1));
            ti += j;
            i += j;
        } else if (ti >= typed.len) {
            const t = std.mem.Allocator.dupeZ(std.heap.c_allocator, u8, text[i..text.len]) catch unreachable;
            rl.drawTextEx(font, t, line_start.add(.{ .x = point.x, .y = 0 }), font_size, 1, constants.grey_color);
            point = point.add(rl.measureTextEx(font, t, font_size, 1));
            return ti;
        } else {
            const t = std.mem.Allocator.dupeZ(std.heap.c_allocator, u8, typed[ti .. ti + 1]) catch unreachable;
            rl.drawTextEx(font, t, line_start.add(.{ .x = point.x, .y = 0 }), font_size, 1, constants.danger_color);
            point = point.add(rl.measureTextEx(font, t, font_size, 1));
            i += 1;
            ti += 1;
        }
    }
    return ti;
}

pub fn main() anyerror!void {
    var state = State.init();

    var text = std.ArrayList(u8).init(std.heap.c_allocator);
    defer text.deinit();
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;
    rl.setConfigFlags(rl.ConfigFlags{ .vsync_hint = true, .window_resizable = true, .msaa_4x_hint = true });

    rl.initWindow(screenWidth, screenHeight, "TypeTrain");
    defer rl.closeWindow(); // Close window and OpenGL context

    const font = rl.loadFontEx("./resources/RobotoMono-Regular.ttf", font_size, null) catch unreachable;
    rl.setTextureFilter(font.texture, .trilinear);

    rl.setTargetFPS(0); // Set our game to run at 60 frames-per-second
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

        drawText(font, state);
        rl.drawFPS(0, 0);

        //----------------------------------------------------------------------------------
    }
}
