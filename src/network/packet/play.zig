const std = @import("std");

const utils = @import("../utils.zig");
const game = @import("../../game/game.zig");
const nbt = @import("../../nbt/nbt.zig");
const Packet = @import("packet.zig").Packet;
const chunk = @import("../../chunk/chunk.zig");

pub const S2CJoinGamePacket = struct {
    pub const PacketID = 0x25;

    base: *Packet,

    entity_id: i32 = 0,
    gamemode: game.Gamemode = .{ .mode = .survival, .hardcode = false },
    previous_gamemode: i8 = -1,
    dimensions: []const []const u8 = &[_][]const u8{"minecraft:world"},
    registry_codec: nbt.NbtTag = undefined,
    dimension_type: []const u8 = "minecraft:overworld",
    dimension_name: []const u8 = "minecraft:world",
    hashed_seed: u64 = 0,
    view_distance: u8 = 8,
    simulation_distace: u8 = 8,
    gamerules: game.Gamerules = .{},
    is_debug: bool = false,
    is_flat: bool = false,

    pub fn init(alloc: std.mem.Allocator) !*S2CJoinGamePacket {
        const base = try Packet.init(alloc);

        const packet = try alloc.create(S2CJoinGamePacket);
        packet.* = .{
            .base = base,
        };
        return packet;
    }

    pub fn deinit(self: *S2CJoinGamePacket, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn encode(self: *S2CJoinGamePacket, alloc: std.mem.Allocator) !*Packet {
        self.base.id = PacketID;

        var buff = std.ArrayList(u8).init(alloc);
        defer buff.deinit();
        const writer = buff.writer();

        // entity id
        try writer.writeInt(i32, self.entity_id, .big);

        // gamemode
        try writer.writeByte(@intFromBool(self.gamemode.hardcode));
        try writer.writeByte(@intFromEnum(self.gamemode.mode));
        try writer.writeInt(i8, self.previous_gamemode, .big);

        try utils.writeVarInt(writer, @as(i32, @intCast(self.dimensions.len)));
        for (self.dimensions) |d|
            try utils.writeByteArray(writer, d);

        // registry codec
        try nbt.serializeTag(writer, self.registry_codec, false);

        // dimensions type
        try utils.writeByteArray(writer, self.dimension_type);

        // dimension name
        try utils.writeByteArray(writer, self.dimension_name);

        // hashed seed
        try writer.writeInt(u64, self.hashed_seed, .big);

        // max players
        try writer.writeByte(0);

        // view distance
        try utils.writeVarInt(writer, self.view_distance);

        // simulation distance
        try utils.writeVarInt(writer, self.simulation_distace);

        // gamerules
        try writer.writeByte(@intFromBool(self.gamerules.reduced_debug_info));
        try writer.writeByte(@intFromBool(self.gamerules.do_immediate_respawn));

        // is debug
        try writer.writeByte(@intFromBool(self.is_debug));

        // is flat
        try writer.writeByte(@intFromBool(self.is_flat));

        // has death location
        try writer.writeByte(0);

        self.base.payload = try buff.toOwnedSlice();
        self.base.length = @as(i32, @intCast(self.base.payload.len)) + 1;

        return self.base;
    }
};

pub const C2SPlayerPositionPacket = struct {
    pub const PacketID = 0x14;

    base: *Packet,

    x: f64,
    y: f64,
    z: f64,
    on_ground: bool,

    pub fn deinit(self: *C2SPlayerPositionPacket, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn decode(alloc: std.mem.Allocator, base: *Packet) !*C2SPlayerPositionPacket {
        var stream = base.getPayloadStream();
        const reader = stream.reader();

        const x = @as(f64, @bitCast(try reader.readInt(i64, .big)));
        const y = @as(f64, @bitCast(try reader.readInt(i64, .big)));
        const z = @as(f64, @bitCast(try reader.readInt(i64, .big)));
        const on_ground = if (try reader.readByte() == 1) true else false;

        const packet = try alloc.create(C2SPlayerPositionPacket);
        packet.* = .{ .base = base, .x = x, .y = y, .z = z, .on_ground = on_ground };
        return packet;
    }
};

pub const C2SPlayerPositionRotationPacket = struct {
    pub const PacketID = 0x15;

    base: *Packet,

    x: f64,
    y: f64,
    z: f64,
    yaw: f32,
    pitch: f32,
    on_ground: bool,

    pub fn deinit(self: *C2SPlayerPositionRotationPacket, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn decode(alloc: std.mem.Allocator, base: *Packet) !*C2SPlayerPositionRotationPacket {
        var stream = base.getPayloadStream();
        const reader = stream.reader();

        const x = @as(f64, @bitCast(try reader.readInt(i64, .big)));
        const y = @as(f64, @bitCast(try reader.readInt(i64, .big)));
        const z = @as(f64, @bitCast(try reader.readInt(i64, .big)));
        const yaw = @as(f32, @bitCast(try reader.readInt(i32, .big)));
        const pitch = @as(f32, @bitCast(try reader.readInt(i32, .big)));
        const on_ground = if (try reader.readByte() == 1) true else false;

        const packet = try alloc.create(C2SPlayerPositionRotationPacket);
        packet.* = .{ .base = base, .x = x, .y = y, .z = z, .yaw = yaw, .pitch = pitch, .on_ground = on_ground };
        return packet;
    }
};

pub const C2SPlayerRotationPacket = struct {
    pub const PacketID = 0x16;

    base: *Packet,

    yaw: f32,
    pitch: f32,
    on_ground: bool,

    pub fn deinit(self: *C2SPlayerRotationPacket, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn decode(alloc: std.mem.Allocator, base: *Packet) !*C2SPlayerRotationPacket {
        var stream = base.getPayloadStream();
        const reader = stream.reader();

        const yaw = @as(f32, @bitCast(try reader.readInt(i32, .big)));
        const pitch = @as(f32, @bitCast(try reader.readInt(i32, .big)));
        const on_ground = if (try reader.readByte() == 1) true else false;

        const packet = try alloc.create(C2SPlayerRotationPacket);
        packet.* = .{ .base = base, .yaw = yaw, .pitch = pitch, .on_ground = on_ground };
        return packet;
    }
};

pub const C2SPlayerAbilitiesPacket = struct {
    pub const PacketID = 0x1c;

    base: *Packet,

    flags: i8,

    pub fn deinit(self: *C2SPlayerAbilitiesPacket, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn decode(alloc: std.mem.Allocator, base: *Packet) !*C2SPlayerAbilitiesPacket {
        var stream = base.getPayloadStream();
        const reader = stream.reader();

        const flags = try reader.readByte();

        const packet = try alloc.create(C2SPlayerAbilitiesPacket);
        packet.* = .{ .base = base, .flags = flags };
        return packet;
    }
};

pub const C2SPlayerCommandPacket = struct {
    pub const PacketID = 0x1e;

    pub const ActionID = enum(u8) { start_sneaking = 0, stop_sneaking = 1, leave_bed = 2, start_sprinting = 3, stop_sprinting = 4, start_jump_with_horse = 5, stop_jump_with_horse = 6, open_horse_inventory = 7, start_flying_with_elytra = 8 };

    base: *Packet,

    player_id: i32,
    action_id: ActionID,
    jump_boost: i32,

    pub fn deinit(self: *C2SPlayerCommandPacket, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn decode(alloc: std.mem.Allocator, base: *Packet) !*C2SPlayerCommandPacket {
        var stream = base.getPayloadStream();
        const reader = stream.reader();

        const player_id = try utils.readVarInt(reader);
        const action_id: ActionID = @enumFromInt(try utils.readVarInt(reader));
        const jump_boost = try utils.readVarInt(reader);

        const packet = try alloc.create(C2SPlayerCommandPacket);
        packet.* = .{ .base = base, .player_id = player_id, .action_id = action_id, .jump_boost = jump_boost };
        return packet;
    }
};

pub const S2CChunkDataPacket = struct {
    pub const PacketID = 0x21;

    base: *Packet,

    chunk: *chunk.Chunk = undefined,

    pub fn init(alloc: std.mem.Allocator) !*S2CChunkDataPacket {
        const base = try Packet.init(alloc);

        const packet = try alloc.create(S2CChunkDataPacket);
        packet.* = .{
            .base = base,
        };
        return packet;
    }

    pub fn deinit(self: *S2CChunkDataPacket, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn encode(self: *S2CChunkDataPacket, alloc: std.mem.Allocator) !*Packet {
        self.base.id = PacketID;

        var buff = std.ArrayList(u8).init(alloc);
        defer buff.deinit();
        const writer = buff.writer();

        try writer.writeInt(i32, self.chunk.x, .big);
        try writer.writeInt(i32, self.chunk.z, .big);

        var heightmap_data_array = try chunk.PackedDataArray.init(alloc, 9, 256);
        defer heightmap_data_array.deinit(alloc);
        var x: u32 = 0;
        while (x < 16) : (x += 1) {
            var z: u32 = 0;
            while (z < 16) : (z += 1) {
                heightmap_data_array.set((x * 16) + z, self.chunk.getHighestBlock(x, z));
            }
        }

        const heightmap_nbt = nbt.NbtTag{
            .tag_compound = .{
                .identifier = "",
                .children = &[_]nbt.NbtTag{
                    .{
                        .tag_long_array = .{
                            .identifier = "MOTION_BLOCKING",
                            .values = @as([]i64, @ptrCast(heightmap_data_array.data)),
                        },
                    },
                },
            },
        };
        try nbt.serializeTag(writer, heightmap_nbt, false);

        var cs_data = std.ArrayList(u8).init(alloc);
        defer cs_data.deinit();
        var cs_writer = cs_data.writer();

        for (self.chunk.sections.values()) |section| {
            try cs_writer.writeInt(i16, @as(i16, @intCast(section.block_count)), .big);

            try cs_writer.writeByte(section.data.element_bits);
            try utils.writeVarInt(cs_writer, @as(i32, @intCast(section.data.data.len)));
            for (section.data.data) |long| {
                try cs_writer.writeInt(i64, @as(i64, @bitCast(long)), .big);
            }

            try cs_writer.writeByte(0);
            try utils.writeVarInt(cs_writer, 0);
            try utils.writeVarInt(cs_writer, 0);
        }
        try utils.writeByteArray(writer, cs_data.items);

        // block entities
        try utils.writeVarInt(writer, 0);

        // trust edges
        try writer.writeByte(1);

        // bitsets
        try utils.writeVarInt(writer, 0);
        try utils.writeVarInt(writer, 0);
        try utils.writeVarInt(writer, 1);
        try writer.writeInt(i64, 0x3FFFF, .big);
        try utils.writeVarInt(writer, 1);
        try writer.writeInt(i64, 0x3FFFF, .big);

        // sky light
        try utils.writeVarInt(writer, 0);

        // block light
        try utils.writeVarInt(writer, 0);

        self.base.payload = try buff.toOwnedSlice();
        self.base.length = @as(i32, @intCast(self.base.payload.len)) + 1;

        return self.base;
    }
};

pub const S2CUnloadChunkPacket = struct {
    pub const PacketID = 0x1c;

    base: *Packet,

    chunk_x: i32 = 0,
    chunk_z: i32 = 0,

    pub fn init(alloc: std.mem.Allocator) !*S2CSetCenterChunk {
        const base = try Packet.init(alloc);

        const packet = try alloc.create(S2CSetCenterChunk);
        packet.* = .{
            .base = base,
        };
        return packet;
    }

    pub fn deinit(self: *S2CSetCenterChunk, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn encode(self: *S2CSetCenterChunk, alloc: std.mem.Allocator) !*Packet {
        self.base.id = PacketID;

        var buff = std.ArrayList(u8).init(alloc);
        defer buff.deinit();
        const writer = buff.writer();

        try writer.writeInt(i32, self.chunk_x, .big);
        try writer.writeInt(i32, self.chunk_z, .big);

        self.base.payload = try buff.toOwnedSlice();
        self.base.length = @as(i32, @intCast(self.base.payload.len)) + 1;

        return self.base;
    }
};

pub const S2CSetCenterChunk = struct {
    pub const PacketID = 0x4B;

    base: *Packet,

    chunk_x: i32 = 0,
    chunk_z: i32 = 0,

    pub fn init(alloc: std.mem.Allocator) !*S2CSetCenterChunk {
        const base = try Packet.init(alloc);

        const packet = try alloc.create(S2CSetCenterChunk);
        packet.* = .{
            .base = base,
        };
        return packet;
    }

    pub fn deinit(self: *S2CSetCenterChunk, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn encode(self: *S2CSetCenterChunk, alloc: std.mem.Allocator) !*Packet {
        self.base.id = PacketID;

        var buff = std.ArrayList(u8).init(alloc);
        defer buff.deinit();
        const writer = buff.writer();

        try utils.writeVarInt(writer, self.chunk_x);
        try utils.writeVarInt(writer, self.chunk_z);

        self.base.payload = try buff.toOwnedSlice();
        self.base.length = @as(i32, @intCast(self.base.payload.len)) + 1;

        return self.base;
    }
};

pub const S2CSynchronizePlayerPosition = struct {
    pub const PacketID = 0x39;

    base: *Packet,

    x: f64 = 0,
    y: f64 = 0,
    z: f64 = 0,

    yaw: f32 = 0,
    pitch: f32 = 0,

    flags: packed struct {
        x: bool = false,
        y: bool = false,
        z: bool = false,
        yaw: bool = false,
        pitch: bool = false,

        _pad: u3 = 0,
    } = .{},
    teleport_id: i32 = 0,
    dismount_vehicle: bool = false,

    pub fn init(alloc: std.mem.Allocator) !*S2CSynchronizePlayerPosition {
        const base = try Packet.init(alloc);

        const packet = try alloc.create(S2CSynchronizePlayerPosition);
        packet.* = .{
            .base = base,
        };
        return packet;
    }

    pub fn deinit(self: *S2CSynchronizePlayerPosition, alloc: std.mem.Allocator) void {
        alloc.destroy(self);
    }

    pub fn encode(self: *S2CSynchronizePlayerPosition, alloc: std.mem.Allocator) !*Packet {
        self.base.id = PacketID;

        var buff = std.ArrayList(u8).init(alloc);
        defer buff.deinit();
        const writer = buff.writer();

        try writer.writeInt(u64, @as(u64, @bitCast(self.x)), .big);
        try writer.writeInt(u64, @as(u64, @bitCast(self.y)), .big);
        try writer.writeInt(u64, @as(u64, @bitCast(self.z)), .big);

        try writer.writeInt(i32, @as(i32, @bitCast(self.yaw)), .big);
        try writer.writeInt(i32, @as(i32, @bitCast(self.pitch)), .big);

        try writer.writeByte(@as(u8, @bitCast(self.flags)));

        try utils.writeVarInt(writer, self.teleport_id);

        try writer.writeByte(@intFromBool(self.dismount_vehicle));

        self.base.payload = try buff.toOwnedSlice();
        self.base.length = @as(i32, @intCast(self.base.payload.len)) + 1;

        return self.base;
    }
};
