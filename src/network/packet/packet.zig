const std = @import("std");

const utils = @import("../utils.zig");

pub usingnamespace @import("handshake.zig");
pub usingnamespace @import("status.zig");
pub usingnamespace @import("login.zig");
pub usingnamespace @import("play.zig");

pub const Packet = struct {
    length: i32,
    id: u8,
    payload: []u8,

    pub fn init(alloc: std.mem.Allocator) !*Packet {
        const packet = try alloc.create(Packet);
        packet.* = .{
            .length = 0,
            .id = 0xFF,
            .payload = undefined,
        };
        return packet;
    }

    pub fn deinit(self: *Packet, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn decode(alloc: std.mem.Allocator, reader: anytype) !*Packet {
        const length = try utils.readVarInt(reader);
        const data = try utils.readByteArray(alloc, reader, length);

        const packet = try alloc.create(Packet);
        packet.* = .{
            .length = length,
            .id = data[0],
            .payload = data[1..],
        };
        return packet;
    }

    pub fn encode(self: *Packet, writer: anytype) !void {
        try utils.writeVarInt(writer, self.length);
        try writer.writeByte(self.id);
        try writer.writeAll(self.payload);
    }

    pub fn getPayloadStream(self: *Packet) std.io.FixedBufferStream([]u8) {
        return std.io.fixedBufferStream(self.payload);
    }
};
