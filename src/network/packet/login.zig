const std = @import("std");

const utils = @import("../utils.zig");
const Packet = @import("packet.zig").Packet;

pub const C2SLoginStartPacket = struct {
    pub const PacketID = 0x00;

    base: *Packet,

    username: []const u8,
    // TODO: Add UUID

    has_sig_data: bool,
    timestamp: ?i64,
    public_key_length: ?i32,
    public_key: ?[]const u8,
    signature_length: ?i32,
    signature: ?[]const u8,

    pub fn deinit(self: *C2SLoginStartPacket, alloc: std.mem.Allocator) void {
        alloc.free(self.username);

        if (self.has_sig_data) {
            alloc.free(self.public_key.?);
            alloc.free(self.signature.?);
        }

        alloc.destroy(self);
    }

    pub fn decode(alloc: std.mem.Allocator, base: *Packet) !*C2SLoginStartPacket {
        var stream = base.getPayloadStream();
        const reader = stream.reader();

        const username = try utils.readByteArray(alloc, reader, try utils.readVarInt(reader));

        const has_sig_data = if (try reader.readByte() == 1) true else false;

        var timestamp: ?i64 = null;
        var public_key_length: ?i32 = null;
        var public_key: ?[]const u8 = null;
        var signature_length: ?i32 = null;
        var signature: ?[]const u8 = null;

        if (has_sig_data) {
            timestamp = try reader.readInt(i64, .big);
            public_key_length = try utils.readVarInt(reader);
            public_key = try utils.readByteArray(alloc, reader, public_key_length.?);
            signature_length = try utils.readVarInt(reader);
            signature = try utils.readByteArray(alloc, reader, signature_length.?);
        }

        const packet = try alloc.create(C2SLoginStartPacket);
        packet.* = .{ .base = base, .username = username, .has_sig_data = has_sig_data, .timestamp = timestamp, .public_key_length = public_key_length, .public_key = public_key, .signature_length = signature_length, .signature = signature };
        return packet;
    }
};

pub const S2CLoginSuccessPacket = struct {
    pub const PacketID = 0x02;

    base: *Packet,

    username: []const u8 = undefined,

    pub fn init(alloc: std.mem.Allocator) !*S2CLoginSuccessPacket {
        const base = try Packet.init(alloc);

        const packet = try alloc.create(S2CLoginSuccessPacket);
        packet.* = S2CLoginSuccessPacket{
            .base = base,
        };
        return packet;
    }

    pub fn deinit(self: *S2CLoginSuccessPacket, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn encode(self: *S2CLoginSuccessPacket, alloc: std.mem.Allocator) !*Packet {
        self.base.id = PacketID;

        var buff = std.ArrayList(u8).init(alloc);
        defer buff.deinit();
        const writer = buff.writer();

        // TODO: Add UUID
        try writer.writeInt(u128, 0xDEADBEEFCAFEBABE, .big);
        try utils.writeByteArray(writer, self.username);

        try utils.writeVarInt(writer, 0);

        self.base.payload = try buff.toOwnedSlice();
        self.base.length = @as(i32, @intCast(self.base.payload.len)) + 1;

        return self.base;
    }
};
