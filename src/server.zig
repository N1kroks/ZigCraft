const std = @import("std");

const Chunk = @import("chunk/chunk.zig").Chunk;
const network = @import("network/network.zig");
const Player = @import("player.zig").Player;
const packet = network.packet;

pub const Server = struct {
    alloc: std.mem.Allocator,
    listener: std.net.Server,

    players: std.ArrayList(Player),
    chunks: std.AutoHashMap(u64, *Chunk),

    next_entity_id: i32,

    pub fn init(alloc: std.mem.Allocator, address: std.net.Address) !Server {
        const listener = try std.net.Address.listen(address, .{});

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

    fn updateChunksForPlayer(self: *Server, stream: std.net.Stream, player: *Player) !void {
        const chunk_x = player.chunkX();
        const chunk_z = player.chunkZ();
        const prev_chunk_x = player.prev_chunk_x;
        const prev_chunk_z = player.prev_chunk_z;

        if (!(chunk_x == prev_chunk_x and chunk_z == prev_chunk_z)) {
            player.prev_chunk_x = chunk_x;
            player.prev_chunk_z = chunk_z;

            const pkt = try packet.S2CSetCenterChunk.init(self.alloc);
            defer pkt.deinit(self.alloc);

            pkt.chunk_x = chunk_x;
            pkt.chunk_z = chunk_z;
            std.debug.print("S2CSetCenterChunk: {}\n", .{pkt});

            const basepkt = try pkt.encode(self.alloc);
            defer basepkt.deinit(self.alloc);
            try basepkt.encode(stream.writer());
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

                        const pkt = try packet.S2CChunkDataPacket.init(self.alloc);
                        pkt.chunk = chunk;

                        const base_pkt = try pkt.encode(self.alloc);
                        defer base_pkt.deinit(self.alloc);
                        try base_pkt.encode(stream.writer());

                        try player.markChunkLoaded(x, z);
                    }
                }
            }
        }
    }

    fn unknownPacketPanic(id: u8, state: network.ConnectionState) noreturn {
        std.debug.panic("Unknown packet with id: {} in state: {}", .{ id, state });
    }

    fn handleConnection(self: *Server, stream: std.net.Stream) !void {
        defer stream.close();

        const reader = stream.reader();
        const writer = stream.writer();
        var state: network.ConnectionState = .handshake;

        var player: Player = undefined;

        while (true) {
            const base_pkt = packet.Packet.decode(self.alloc, reader) catch |err| switch (err) {
                error.BrokenPipe, error.EndOfStream => break,
                else => {
                    std.debug.print("Failed to decode packet: {s}\n", .{@errorName(err)});
                    return err;
                },
            };

            switch (state) {
                .handshake => {
                    switch (base_pkt.id) {
                        packet.C2SHandshakePacket.PacketID => {
                            const pkt = try packet.C2SHandshakePacket.decode(self.alloc, base_pkt);
                            defer pkt.deinit(self.alloc);
                            state = pkt.next_state;
                        },
                        else => unknownPacketPanic(base_pkt.id, state),
                    }
                },
                .status => {
                    switch (base_pkt.id) {
                        packet.C2SStatusRequestPacket.PacketID => {
                            const pkt = try packet.S2CStatusResponsePacket.init(self.alloc);
                            defer pkt.deinit(self.alloc);

                            pkt.response = try self.alloc.dupe(u8,
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
                            );

                            const basepkt = try pkt.encode(self.alloc);
                            defer basepkt.deinit(self.alloc);
                            try basepkt.encode(writer);
                        },
                        packet.C2SPingRequestPacket.PacketID => {
                            const pkt = try packet.C2SPingRequestPacket.decode(self.alloc, base_pkt);
                            defer pkt.deinit(self.alloc);

                            const spkt = try packet.S2CPingResponsePacket.init(self.alloc);
                            defer spkt.deinit(self.alloc);

                            spkt.payload = pkt.payload;

                            const basepkt = try spkt.encode(self.alloc);
                            defer basepkt.deinit(self.alloc);
                            try basepkt.encode(writer);
                        },
                        else => unknownPacketPanic(base_pkt.id, state),
                    }
                },
                .login => {
                    switch (base_pkt.id) {
                        packet.C2SLoginStartPacket.PacketID => {
                            const pkt = try packet.C2SLoginStartPacket.decode(self.alloc, base_pkt);
                            defer pkt.deinit(self.alloc);

                            {
                                const spkt = try packet.S2CLoginSuccessPacket.init(self.alloc);
                                defer spkt.deinit(self.alloc);

                                player = try Player.init(self.alloc, self.next_entity_id, pkt.username);
                                try self.players.append(player);

                                spkt.username = pkt.username;

                                const basepkt = try spkt.encode(self.alloc);
                                defer basepkt.deinit(self.alloc);
                                try basepkt.encode(writer);
                            }

                            state = .play;

                            {
                                const spkt = try packet.S2CJoinGamePacket.init(self.alloc);
                                defer spkt.deinit(self.alloc);
                                spkt.entity_id = self.next_entity_id;
                                self.next_entity_id += 1;
                                spkt.gamemode = .{
                                    .mode = .creative,
                                    .hardcode = false,
                                };
                                spkt.registry_codec = network.BASIC_REGISTRY_CODEC;

                                const basepkt = try spkt.encode(self.alloc);
                                defer basepkt.deinit(self.alloc);
                                try basepkt.encode(writer);
                            }

                            {
                                const spkt = try packet.S2CSynchronizePlayerPosition.init(self.alloc);
                                defer spkt.deinit(self.alloc);
                                spkt.x = player.x;
                                spkt.y = player.y;
                                spkt.z = player.z;

                                const basepkt = try spkt.encode(self.alloc);
                                defer basepkt.deinit(self.alloc);
                                try basepkt.encode(writer);
                            }

                            try self.updateChunksForPlayer(stream, &player);

                            std.debug.print("Player {s} successfully joined game\n", .{pkt.username});
                        },
                        else => unknownPacketPanic(base_pkt.id, state),
                    }
                },
                .play => {
                    switch (base_pkt.id) {
                        0x00, // C2SConfirmTeleportation
                        0x08, // C2SClientInformation
                        0x0d, // C2SPluginMessage
                        => {},
                        packet.C2SPlayerPositionPacket.PacketID => {
                            const pkt = try packet.C2SPlayerPositionPacket.decode(self.alloc, base_pkt);
                            defer pkt.deinit(self.alloc);
                            player.x = pkt.x;
                            player.y = pkt.y;
                            player.z = pkt.z;
                            try self.updateChunksForPlayer(stream, &player);
                        },
                        packet.C2SPlayerPositionRotationPacket.PacketID => {
                            const pkt = try packet.C2SPlayerPositionRotationPacket.decode(self.alloc, base_pkt);
                            defer pkt.deinit(self.alloc);
                            player.x = pkt.x;
                            player.y = pkt.y;
                            player.z = pkt.z;
                            player.yaw = pkt.yaw;
                            player.pitch = pkt.pitch;
                            try self.updateChunksForPlayer(stream, &player);
                        },
                        packet.C2SPlayerRotationPacket.PacketID => {
                            const pkt = try packet.C2SPlayerRotationPacket.decode(self.alloc, base_pkt);
                            defer pkt.deinit(self.alloc);
                            player.yaw = pkt.yaw;
                            player.pitch = pkt.pitch;
                        },
                        packet.C2SPlayerAbilitiesPacket.PacketID => {},
                        packet.C2SPlayerCommandPacket.PacketID => {},
                        else => std.debug.print("Unknown play packet with id: 0x{x}\n", .{base_pkt.id}),
                    }
                },
            }

            base_pkt.deinit(self.alloc);
        }
    }
};
