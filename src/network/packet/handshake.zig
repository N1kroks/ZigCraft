const std = @import("std");

const utils = @import("../utils.zig");
const Packet = @import("packet.zig").Packet;
const ConnectionState = @import("../connection_state.zig").ConnectionState;

pub const C2SHandshakePacket = struct {
    pub const PacketID = 0x00;

    base: *Packet,

    protocol_version: i32,
    hostname: []const u8,
    port: u16,
    next_state: ConnectionState,

    pub fn deinit(self: *C2SHandshakePacket, alloc: std.mem.Allocator) void {
        alloc.free(self.hostname);
        alloc.destroy(self);
    }

    pub fn decode(alloc: std.mem.Allocator, base: *Packet) !*C2SHandshakePacket {
        var stream = base.getPayloadStream();
        const reader = stream.reader();

        const protocol_version = try utils.readVarInt(reader);
        const hostname = try utils.readByteArray(alloc, reader, try utils.readVarInt(reader));
        const port = try reader.readInt(u16, .big);
        const next_state: ConnectionState = @enumFromInt(try reader.readInt(u8, .big));

        const packet = try alloc.create(C2SHandshakePacket);
        packet.* = .{
            .base = base,
            .protocol_version = protocol_version,
            .hostname = hostname,
            .port = port,
            .next_state = next_state,
        };
        return packet;
    }
};
