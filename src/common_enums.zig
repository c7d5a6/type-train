pub const CharState = enum {
    correct,
    not_typed,
    wrong,
    wrong_over,
};
pub const TypedStateType = enum {
    correct,
    wrong,
    wrong_over,
    whitespace,
};
pub const TypedState = union(TypedStateType) {
    correct: u8,
    wrong: u8,
    wrong_over: void,
    whitespace: void,
};
