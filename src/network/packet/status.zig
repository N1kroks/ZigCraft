const std = @import("std");

const packet = @import("packet.zig");

pub const C2SStatusRequestPacket = struct {
    pub const PacketID = 0x00;
};

pub const S2CStatusResponsePacket = struct {
    pub const PacketID = 0x00;

    response: packet.String = undefined,
};

pub const PingPacket = struct {
    pub const PacketID = 0x01;
    payload: i64,
};
