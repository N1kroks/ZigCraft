const std = @import("std");

const Chunk = @import("chunk/chunk.zig").Chunk;
const network = @import("network/network.zig");
const Player = @import("player.zig").Player;
const packet = network.packet;

const KEEPALIVE_INTERVAL_MS = 20000;
const KEEPALIVE_TIMEOUT_MS = 30000;

pub const Server = struct {
    alloc: std.mem.Allocator,
    listener: std.net.Server,

    players: std.ArrayList(Player),
    chunks: std.AutoHashMap(u64, *Chunk),

    next_entity_id: i32,

    pub fn init(alloc: std.mem.Allocator, address: std.net.Address) !Server {
        const listener = try std.net.Address.listen(address, .{ .reuse_address = true });

        return Server{
            .alloc = alloc,
            .listener = listener,

            .players = std.ArrayList(Player).init(alloc),
            .chunks = std.AutoHashMap(u64, *Chunk).init(alloc),

            .next_entity_id = 0,
        };
    }

    pub fn deinit(self: *Server) void {
        for (self.players.items) |*player| {
            player.deinit(self.alloc);
        }
        self.players.deinit();

        var iter = self.chunks.iterator();
        while (iter.next()) |entry| {
            const chunk = entry.value_ptr.*;
            chunk.deinit(self.alloc);
        }
        self.chunks.deinit();

        self.listener.deinit();
    }

    fn chunkKey(x: i32, z: i32) u64 {
        return (@as(u64, @as(u32, @bitCast(x))) << 32) | @as(u64, @as(u32, @bitCast(z)));
    }

    fn generateSpawnChunks(self: *Server) !void {
        const spawn_radius = 5; // TODO: move to config

        var x: i32 = -spawn_radius;
        while (x <= spawn_radius) : (x += 1) {
            var z: i32 = -spawn_radius;
            while (z <= spawn_radius) : (z += 1) {
                try self.chunks.put(chunkKey(x, z), try Chunk.init(self.alloc, x, z, 256));
            }
        }
    }

    pub fn start(self: *Server) !void {
        try self.generateSpawnChunks();

        while (true) {
            const client = self.listener.accept() catch |err| {
                std.debug.print("Error while attemping to accept client: {}\n", .{err});
                continue;
            };

            const thread = try std.Thread.spawn(.{}, handleConnection, .{ self, client.stream });
            thread.detach();
        }
    }

    fn updateChunksForPlayer(self: *Server, packet_writer: *packet.PacketWriter, writer: anytype, player: *Player) !void {
        const chunk_x = player.chunkX();
        const chunk_z = player.chunkZ();
        const prev_chunk_x = player.prev_chunk_x;
        const prev_chunk_z = player.prev_chunk_z;

        if (!(chunk_x == prev_chunk_x and chunk_z == prev_chunk_z)) {
            player.prev_chunk_x = chunk_x;
            player.prev_chunk_z = chunk_z;

            const pkt = packet.S2CSetCenterChunk{
                .chunk_x = .init(chunk_x),
                .chunk_z = .init(chunk_z),
            };
            try packet_writer.write(writer, pkt);
        }
        const view_distance = 8; // TODO: Move to config

        {
            var x: i32 = chunk_x - view_distance;
            while (x <= chunk_x + view_distance) : (x += 1) {
                var z: i32 = chunk_z - view_distance;
                while (z <= chunk_z + view_distance) : (z += 1) {
                    const key = chunkKey(x, z);
                    if (!player.isChunkLoaded(x, z)) {
                        if (!self.chunks.contains(key)) {
                            try self.chunks.put(chunkKey(x, z), try Chunk.init(self.alloc, x, z, 256));
                        }

                        const chunk = self.chunks.get(key) orelse continue;

                        const pkt = packet.S2CChunkDataPacket{
                            .chunk = chunk,
                        };
                        try packet_writer.write(writer, pkt);

                        try player.markChunkLoaded(x, z);
                    }
                }
            }
        }
    }

    fn unknownPacketPanic(id: i32, state: network.ConnectionState) noreturn {
        std.debug.panic("Unknown packet with id: {} in state: {}", .{ id, state });
    }

    fn handleConnection(self: *Server, stream: std.net.Stream) !void {
        defer stream.close();

        const reader = stream.reader();
        const writer = stream.writer();
        var packet_reader = packet.PacketReader.init(self.alloc);
        var packet_writer = packet.PacketWriter.init(self.alloc);
        var state: network.ConnectionState = .handshake;

        var player: Player = undefined;

        while (true) {
            const header = packet_reader.read(reader, packet.PacketHeader) catch |err| switch (err) {
                error.BrokenPipe, error.EndOfStream => break,
                else => {
                    std.debug.print("Failed to read packet: {s}\n", .{@errorName(err)});
                    return err;
                },
            };

            switch (state) {
                .handshake => {
                    switch (header.id.value) {
                        packet.C2SHandshakePacket.PacketID => {
                            const pkt = try packet_reader.read(reader, packet.C2SHandshakePacket);
                            state = pkt.next_state;
                        },
                        else => unknownPacketPanic(header.id.value, state),
                    }
                },
                .status => {
                    switch (header.id.value) {
                        packet.C2SStatusRequestPacket.PacketID => {
                            const pkt = packet.S2CStatusResponsePacket{ .response = .init(try self.alloc.dupe(u8,
                                \\{
                                \\    "version": {
                                \\        "name": "1.19.2",
                                \\        "protocol": 760
                                \\    },
                                \\    "players": {
                                \\        "max": 32,
                                \\        "online": 0
                                \\    },
                                \\    "description": {
                                \\        "text": "Welcome to ZigCraft"
                                \\    },
                                \\    "previewsChat": false,
                                \\    "enforcesSecureChat": false
                                \\}
                            )) };
                            try packet_writer.write(writer, pkt);
                        },
                        packet.PingPacket.PacketID => {
                            const pkt = try packet_reader.read(reader, packet.PingPacket);
                            try packet_writer.write(writer, pkt);
                        },
                        else => unknownPacketPanic(header.id.value, state),
                    }
                },
                .login => {
                    switch (header.id.value) {
                        packet.C2SLoginStartPacket.PacketID => {
                            const pkt = try packet_reader.read(reader, packet.C2SLoginStartPacket);

                            {
                                const spkt = packet.S2CLoginSuccessPacket{
                                    .username = pkt.username,
                                    .uuid = 0xDEADBEEFCAFEBABE, // TODO: Generate UUID
                                };
                                try packet_writer.write(writer, spkt);

                                player = try Player.init(self.alloc, self.next_entity_id, pkt.username.data);
                                try self.players.append(player);
                            }

                            state = .play;

                            {
                                const spkt = packet.S2CLoginPlayPacket{
                                    .entity_id = self.next_entity_id,
                                    .registry_codec = network.BASIC_REGISTRY_CODEC,
                                };
                                try packet_writer.write(writer, spkt);
                            }

                            {
                                const spkt = packet.S2CSynchronizePlayerPosition{
                                    .x = player.x,
                                    .y = player.y,
                                    .z = player.z,
                                };
                                try packet_writer.write(writer, spkt);
                            }

                            try self.updateChunksForPlayer(&packet_writer, writer, &player);

                            std.debug.print("Player {s} successfully joined game\n", .{pkt.username.data});
                        },
                        else => unknownPacketPanic(header.id.value, state),
                    }
                },
                .play => {
                    const now = std.time.milliTimestamp();

                    if (now - player.last_keepalive_time >= KEEPALIVE_INTERVAL_MS) {
                        if (player.pending_keepalive and (now - player.last_keepalive_time >= KEEPALIVE_TIMEOUT_MS)) {
                            std.debug.print("Player {s} timed out\n", .{player.name});
                            stream.close();
                        }

                        if (!player.pending_keepalive) {
                            player.last_keepalive_id = now;
                            player.last_keepalive_time = now;
                            player.pending_keepalive = true;

                            const pkt = packet.S2CKeepAlivePacket{ .keep_alive_id = player.last_keepalive_id };
                            try packet_writer.write(writer, pkt);
                        }
                    }

                    switch (header.id.value) {
                        packet.C2SPlayerPositionPacket.PacketID => {
                            const pkt = try packet_reader.read(reader, packet.C2SPlayerPositionPacket);
                            player.x = pkt.x;
                            player.y = pkt.y;
                            player.z = pkt.z;
                            try self.updateChunksForPlayer(&packet_writer, writer, &player);
                        },
                        packet.C2SPlayerPositionRotationPacket.PacketID => {
                            const pkt = try packet_reader.read(reader, packet.C2SPlayerPositionRotationPacket);
                            player.x = pkt.x;
                            player.y = pkt.y;
                            player.z = pkt.z;
                            player.yaw = pkt.yaw;
                            player.pitch = pkt.pitch;
                            try self.updateChunksForPlayer(&packet_writer, writer, &player);
                        },
                        packet.C2SPlayerRotationPacket.PacketID => {
                            const pkt = try packet_reader.read(reader, packet.C2SPlayerRotationPacket);
                            player.yaw = pkt.yaw;
                            player.pitch = pkt.pitch;
                        },
                        packet.C2SKeepAlivePacket.PacketID => {
                            const pkt = try packet_reader.read(reader, packet.C2SKeepAlivePacket);
                            if (player.pending_keepalive and pkt.keep_alive_id == player.last_keepalive_id) {
                                player.pending_keepalive = false;
                            }
                        },
                        packet.C2SClientInformationPacket.PacketID,
                        packet.C2SConfirmTeleportPacket.PacketID,
                        packet.C2SPlayerAbilitiesPacket.PacketID,
                        packet.C2SPlayerCommandPacket.PacketID,
                        => {
                            try reader.skipBytes(@as(u64, @intCast(header.length.value)) - 1, .{});
                        },
                        else => {
                            try reader.skipBytes(@as(u64, @intCast(header.length.value)) - 1, .{});
                            std.debug.print("Unknown play packet with id: 0x{x}\n", .{header.id.value});
                        },
                    }
                },
            }
        }
    }
};
