pub const CharState = enum {
    correct,
    not_typed,
    wrong,
    wrong_over,
};

pub fn charState(exercise: []const u21, typed: []const u21, ie: u8, it: u8) CharState {
    if (exercise.len <= ie) return .wrong_over;
    if (typed.len <= it) return .not_typed;
    if (exercise[ie] == typed[it]) return .correct;
    if (exercise[ie] == ' ') return .wrong_over;
    if (typed[it] == ' ') return .not_typed;
    return .wrong;
}
