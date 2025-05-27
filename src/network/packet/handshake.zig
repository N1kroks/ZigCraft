const std = @import("std");

const packet = @import("packet.zig");
const ConnectionState = @import("../connection_state.zig").ConnectionState;

pub const C2SHandshakePacket = struct {
    pub const PacketID = 0x00;

    protocol_version: packet.VarInt,
    hostname: packet.String,
    port: u16,
    next_state: ConnectionState,
};
