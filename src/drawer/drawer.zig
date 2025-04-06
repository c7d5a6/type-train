const std = @import("std");
const rl = @import("raylib");
const cnst = @import("../constants.zig");
const State = @import("../state.zig").State;
const TextDrawer = @import("text-drawer.zig").TextDrawer;
const StatDrawer = @import("stat-drawer.zig").StatDrawer;

pub const Drawer = struct {
    text_drawer: TextDrawer,
    stat_drawer: StatDrawer,
    state: *State,

    pub fn init(state: *State) Drawer {
        return Drawer{
            .state = state,
            .text_drawer = TextDrawer.init(state),
            .stat_drawer = StatDrawer.init(state),
        };
    }

    pub fn draw(self: Drawer) void {
        switch (self.state.state) {
            .exercise => {
                rl.setTargetFPS(0);
                rl.enableEventWaiting();
            },
            else => {
                rl.setTargetFPS(120);
                rl.disableEventWaiting();
            },
        }
        rl.clearBackground(cnst.background_color);
        switch (self.state.state) {
            .exercise => self.text_drawer.drawText(),
            .stats => self.stat_drawer.drawStats(),
            else => {},
        }
    }
};
