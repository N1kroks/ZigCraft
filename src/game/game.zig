pub const Gamemode = struct {
    hardcode: bool,
    mode: enum(u8) {
        survival,
        creative,
        adventure,
        spectator,
    },
};

pub const Gamerules = struct {
    reduced_debug_info: bool = false,
    do_immediate_respawn: bool = false,
};
