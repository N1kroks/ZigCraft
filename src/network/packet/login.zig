const std = @import("std");

const packet = @import("packet.zig");

pub const C2SLoginStartPacket = struct {
    pub const PacketID = 0x00;

    username: packet.String,

    has_sig_data: bool,
    timestamp: ?i64,
    public_key_length: ?packet.VarInt,
    public_key: ?packet.ByteArray,
    signature_length: ?packet.VarInt,
    signature: ?packet.ByteArray,

    has_player_uuid: bool,
    player_uuid: ?packet.UUID,

    pub fn write(self: C2SLoginStartPacket, alloc: std.mem.Allocator, writer: anytype) !void {
        _ = self;
        _ = alloc;
        _ = writer;
        @compileError("writing of packet C2SLoginStartPacket is not implemented yet");
    }

    pub fn read(alloc: std.mem.Allocator, reader: anytype) !C2SLoginStartPacket {
        const username = try packet.String.read(alloc, reader);
        const has_sig_data = try reader.readByte() == 1;

        var timestamp: ?i64 = null;
        var public_key_length: ?packet.VarInt = null;
        var public_key: ?packet.ByteArray = null;
        var signature_length: ?packet.VarInt = null;
        var signature: ?packet.ByteArray = null;

        if (has_sig_data) {
            timestamp = try reader.readInt(i64, .big);
            public_key_length = try packet.VarInt.read(reader);
            public_key = try packet.ByteArray.read(alloc, @intCast(public_key_length.?.value), reader);
            signature_length = try packet.VarInt.read(reader);
            signature = try packet.ByteArray.read(alloc, @intCast(signature_length.?.value), reader);
        }

        const has_player_uuid = try reader.readByte() == 1;

        var player_uuid: ?packet.UUID = null;

        if (has_player_uuid) {
            player_uuid = try packet.UUID.read(reader);
        }

        return .{
            .username = username,

            .has_sig_data = has_sig_data,
            .timestamp = timestamp,
            .public_key_length = public_key_length,
            .public_key = public_key,
            .signature_length = signature_length,
            .signature = signature,

            .has_player_uuid = has_player_uuid,
            .player_uuid = player_uuid,
        };
    }
};

pub const S2CLoginSuccessPacket = struct {
    pub const PacketID = 0x02;

    uuid: packet.UUID = undefined,
    username: packet.String = undefined,

    number_of_properties: packet.VarInt = .init(0),
};
