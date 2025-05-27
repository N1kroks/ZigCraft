const std = @import("std");

const game = @import("game/game.zig");

pub const Player = struct {
    id: i32,
    name: []const u8,

    x: f64,
    y: f64,
    z: f64,

    yaw: f32,
    pitch: f32,

    gamemode: game.Gamemode,

    loaded_chunks: std.AutoHashMap(u64, bool),
    loaded_chunks_lock: std.Thread.Mutex,

    prev_chunk_x: i32,
    prev_chunk_z: i32,

    pub fn init(alloc: std.mem.Allocator, id: i32, name: []const u8) !Player {
        return Player{
            .id = id,
            .name = try alloc.dupe(u8, name),

            .x = 0.0,
            .y = 16.0,
            .z = 0.0,

            .yaw = 0.0,
            .pitch = 0.0,

            .gamemode = .{ .mode = .creative, .hardcode = false },

            .loaded_chunks = std.AutoHashMap(u64, bool).init(alloc),
            .loaded_chunks_lock = std.Thread.Mutex{},

            .prev_chunk_x = 0,
            .prev_chunk_z = 0,
        };
    }

    fn chunkKey(x: i32, z: i32) u64 {
        return (@as(u64, @as(u32, @bitCast(x))) << 32) | @as(u64, @as(u32, @bitCast(z)));
    }

    pub fn deinit(self: *Player, alloc: std.mem.Allocator) void {
        alloc.free(self.name);
        self.loaded_chunks.deinit();
    }

    pub fn isChunkLoaded(self: *Player, x: i32, z: i32) bool {
        const key = chunkKey(x, z);
        return self.loaded_chunks.contains(key);
    }

    pub fn markChunkLoaded(self: *Player, x: i32, z: i32) !void {
        const key = chunkKey(x, z);
        try self.loaded_chunks.put(key, true);
    }

    pub fn markChunkUnloaded(self: *Player, x: i32, z: i32) void {
        const key = chunkKey(x, z);
        _ = self.loaded_chunks.remove(key);
    }

    pub inline fn chunkX(self: *Player) i32 {
        return @divFloor(@as(i32, @intFromFloat(self.x)), 16);
    }

    pub inline fn chunkZ(self: *Player) i32 {
        return @divFloor(@as(i32, @intFromFloat(self.z)), 16);
    }
};
