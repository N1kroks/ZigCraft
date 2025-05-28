const std = @import("std");

const game = @import("../../game/game.zig");
const nbt = @import("../../nbt/nbt.zig");
const packet = @import("packet.zig");
const chunk = @import("../../chunk/chunk.zig");

pub const C2SConfirmTeleportPacket = struct {
    pub const PacketID = 0x00;

    id: packet.VarInt,
};

pub const C2SClientInformationPacket = struct {
    pub const PacketID = 0x08;

    locale: packet.String,

    view_distance: i8,

    chat_mode: enum(u8) { enabled, commands_only, hidden },
    chat_colors: bool,

    displayed_skin_parts: u8,
    main_hand: enum(u8) { left, right },

    enable_text_filtering: bool,
    allow_server_listings: bool,
};

pub const C2SKeepAlivePacket = struct {
    pub const PacketID = 0x12;

    keep_alive_id: i64,
};

pub const C2SPlayerPositionPacket = struct {
    pub const PacketID = 0x14;

    x: f64,
    y: f64,
    z: f64,

    on_ground: bool,
};

pub const C2SPlayerPositionRotationPacket = struct {
    pub const PacketID = 0x15;

    x: f64,
    y: f64,
    z: f64,

    yaw: f32,
    pitch: f32,

    on_ground: bool,
};

pub const C2SPlayerRotationPacket = struct {
    pub const PacketID = 0x16;

    yaw: f32,
    pitch: f32,
    on_ground: bool,
};

pub const C2SPlayerAbilitiesPacket = struct {
    pub const PacketID = 0x1c;

    flags: i8,
};

pub const S2CUnloadChunkPacket = struct {
    pub const PacketID = 0x1c;

    chunk_x: i32,
    chunk_z: i32,
};

pub const C2SPlayerCommandPacket = struct {
    pub const PacketID = 0x1e;

    pub const ActionID = enum(u8) { start_sneaking = 0, stop_sneaking = 1, leave_bed = 2, start_sprinting = 3, stop_sprinting = 4, start_jump_with_horse = 5, stop_jump_with_horse = 6, open_horse_inventory = 7, start_flying_with_elytra = 8 };

    player_id: packet.VarInt,
    action_id: ActionID,
    jump_boost: packet.VarInt,
};

pub const S2CKeepAlivePacket = struct {
    pub const PacketID = 0x20;

    keep_alive_id: i64,
};

pub const S2CChunkDataPacket = struct {
    pub const PacketID = 0x21;

    chunk: *chunk.Chunk = undefined,

    pub fn read(alloc: std.mem.Allocator, reader: anytype) !S2CChunkDataPacket {
        _ = alloc;
        _ = reader;
        @compileError("reading of packet S2CChunkDataPacket is not implemented yet");
    }

    pub fn write(self: S2CChunkDataPacket, alloc: std.mem.Allocator, writer: anytype) !void {
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
            try packet.VarInt.init(@as(i32, @intCast(section.data.data.len))).write(cs_writer);
            for (section.data.data) |long| {
                try cs_writer.writeInt(i64, @as(i64, @bitCast(long)), .big);
            }

            try cs_writer.writeByte(0);
            try packet.VarInt.init(0).write(cs_writer);
            try packet.VarInt.init(0).write(cs_writer);
        }

        try packet.VarInt.init(@as(i32, @intCast(cs_data.items.len))).write(writer);
        try packet.ByteArray.init(cs_data.items).write(writer);

        // block entities
        try packet.VarInt.init(0).write(writer);

        // trust edges
        try writer.writeByte(1);

        // bitsets
        try packet.VarInt.init(0).write(writer);
        try packet.VarInt.init(0).write(writer);
        try packet.VarInt.init(1).write(writer);
        try writer.writeInt(i64, 0x3FFFF, .big);
        try packet.VarInt.init(1).write(writer);
        try writer.writeInt(i64, 0x3FFFF, .big);

        // sky light
        try packet.VarInt.init(0).write(writer);

        // block light
        try packet.VarInt.init(0).write(writer);
    }
};

pub const S2CLoginPlayPacket = struct {
    pub const PacketID = 0x25;

    entity_id: i32 = undefined,

    gamemode: game.Gamemode = .{ .hardcode = false, .mode = .creative },
    previous_gamemode: i8 = -1,

    dimension_count: packet.VarInt = .init(1),
    dimensions: []const packet.String = &[_]packet.String{packet.String.init("minecraft:overworld")},

    registry_codec: nbt.NbtTag = undefined,

    dimension_type: packet.String = .init("minecraft:overworld"),
    dimension_name: packet.String = .init("minecraft:overworld"),

    hashed_seed: u64 = 0,

    max_players: packet.VarInt = .init(0),
    view_distance: packet.VarInt = .init(8),
    simulation_distace: packet.VarInt = .init(8),

    gamerules: game.Gamerules = .{ .reduced_debug_info = false, .do_immediate_respawn = false },

    is_debug: bool = false,
    is_flat: bool = false,

    has_deadth_location: bool = false,
};

pub const S2CSynchronizePlayerPosition = struct {
    pub const PacketID = 0x39;

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

    pub fn read(alloc: std.mem.Allocator, reader: anytype) !S2CChunkDataPacket {
        _ = alloc;
        _ = reader;
        @compileError("reading of packet S2CSynchronizePlayerPosition is not implemented yet");
    }

    pub fn write(self: S2CSynchronizePlayerPosition, alloc: std.mem.Allocator, writer: anytype) !void {
        _ = alloc;

        try writer.writeInt(u64, @as(u64, @bitCast(self.x)), .big);
        try writer.writeInt(u64, @as(u64, @bitCast(self.y)), .big);
        try writer.writeInt(u64, @as(u64, @bitCast(self.z)), .big);

        try writer.writeInt(i32, @as(i32, @bitCast(self.yaw)), .big);
        try writer.writeInt(i32, @as(i32, @bitCast(self.pitch)), .big);

        try writer.writeByte(@as(u8, @bitCast(self.flags)));

        try packet.VarInt.init(self.teleport_id).write(writer);

        try writer.writeByte(@intFromBool(self.dismount_vehicle));
    }
};

pub const S2CSetCenterChunk = struct {
    pub const PacketID = 0x4B;

    chunk_x: packet.VarInt,
    chunk_z: packet.VarInt,
};
