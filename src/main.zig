const rl = @import("raylib");
const std = @import("std");

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;
    rl.setConfigFlags(rl.ConfigFlags{ .vsync_hint = true });

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    // rl.setTargetFPS(240); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------
    var keyTime: ?i128 = null;
    var prevTime = std.time.nanoTimestamp();

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------
        if (keyTime) |time| {
            const curtime = std.time.nanoTimestamp();
            const delta = curtime - prevTime;
            prevTime = curtime;
            // if (time != 0) {
            // const hours = @divFloor(time, 3_600_000_000_000);
            // const minutes = @divFloor(@mod(time, 3_600_000_000_000), 60_000_000_000);
            // const seconds = @divFloor(@mod(time, 60_000_000_000), 1_000_000_000);
            // const milliseconds = @divFloor(@mod(time, 1_000_000_000), 1_000_000);
            // const microseconds = @divFloor(@mod(time, 1_000_000), 1_000);
            // const nanoseconds = @mod(time, 1_000);
            // std.debug.print("{d}:{d}:{}.{}.{}.{}\n", .{ hours, minutes, seconds, milliseconds, microseconds, nanoseconds });
            //     // }
            //     keyTime = 0;
            // } else {
            keyTime = time + delta;
            // }
            const ch = rl.getCharPressed();
            if (ch != 0) {
                var s: [4]u8 = undefined;
                std.mem.writePackedInt(i32, s[0..], 0, ch, .little);
                std.debug.print("Pressed {s} in time {d}\n", .{ s, time });
            }
        } else {
            keyTime = 0;
        }
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.init(28, 28, 28, 255));

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
        rl.drawFPS(0, 0);

        //----------------------------------------------------------------------------------
    }
}
