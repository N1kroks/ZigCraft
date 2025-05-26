const std = @import("std");

const utils = @import("../utils.zig");
const Packet = @import("packet.zig").Packet;

pub const C2SStatusRequestPacket = struct {
    pub const PacketID = 0x00;

    base: *Packet,

    pub fn deinit(self: *C2SStatusRequestPacket, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn decode(alloc: std.mem.Allocator, base: *Packet) !*C2SStatusRequestPacket {
        const packet = try alloc.create(C2SStatusRequestPacket);
        packet.* = .{
            .base = base,
        };
        return packet;
    }
};

pub const S2CStatusResponsePacket = struct {
    pub const PacketID = 0x00;

    base: *Packet,

    response: []const u8 = undefined,

    pub fn init(alloc: std.mem.Allocator) !*S2CStatusResponsePacket {
        const base = try Packet.init(alloc);

        const packet = try alloc.create(S2CStatusResponsePacket);
        packet.* = .{
            .base = base,
        };
        return packet;
    }

    pub fn deinit(self: *S2CStatusResponsePacket, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn encode(self: *S2CStatusResponsePacket, alloc: std.mem.Allocator) !*Packet {
        self.base.id = PacketID;

        var buff = std.ArrayList(u8).init(alloc);
        defer buff.deinit();
        const writer = buff.writer();

        try utils.writeByteArray(writer, self.response);

        self.base.payload = try buff.toOwnedSlice();
        self.base.length = @as(i32, @intCast(self.base.payload.len)) + 1;

        return self.base;
    }
};

pub const C2SPingRequestPacket = struct {
    pub const PacketID = 0x01;

    base: *Packet,

    payload: i64,

    pub fn deinit(self: *C2SPingRequestPacket, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn decode(alloc: std.mem.Allocator, base: *Packet) !*C2SPingRequestPacket {
        var stream = base.getPayloadStream();
        const reader = stream.reader();

        const payload = try reader.readInt(i64, .big);

        const packet = try alloc.create(C2SPingRequestPacket);
        packet.* = .{ .base = base, .payload = payload };
        return packet;
    }
};

pub const S2CPingResponsePacket = struct {
    pub const PacketID = 0x01;

    base: *Packet,

    payload: i64 = undefined,

    pub fn init(alloc: std.mem.Allocator) !*S2CPingResponsePacket {
        const base = try Packet.init(alloc);

        const packet = try alloc.create(S2CPingResponsePacket);
        packet.* = .{
            .base = base,
        };
        return packet;
    }

    pub fn deinit(self: *S2CPingResponsePacket, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn encode(self: *S2CPingResponsePacket, alloc: std.mem.Allocator) !*Packet {
        self.base.id = PacketID;

        var buff = std.ArrayList(u8).init(alloc);
        defer buff.deinit();
        const writer = buff.writer();

        try writer.writeInt(i64, self.payload, .big);

        self.base.payload = try buff.toOwnedSlice();
        self.base.length = @as(i32, @intCast(self.base.payload.len)) + 1;

        return self.base;
    }
};
