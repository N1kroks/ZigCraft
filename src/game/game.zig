pub const Gamemode = struct {
    mode: enum(u8) {
        survival,
        creative,
        adventure,
        spectator,
    },
    hardcode: bool,
};

pub const Gamerules = struct {
    do_immediate_respawn: bool = false,
    reduced_debug_info: bool = false,
};
