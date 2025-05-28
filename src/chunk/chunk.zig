const std = @import("std");

const ChunkSection = @import("chunk_section.zig").ChunkSection;
pub const PackedDataArray = @import("packed_data_array.zig").PackedDataArray;

pub const Chunk = struct {
    sections: std.AutoArrayHashMap(u8, ChunkSection),

    x: i32,
    z: i32,

    pub fn init(alloc: std.mem.Allocator, x: i32, z: i32, world_height: i32) !*Chunk {
        var chunk = try alloc.create(Chunk);
        chunk.* = Chunk{
            .sections = std.AutoArrayHashMap(u8, ChunkSection).init(alloc),
            .x = x,
            .z = z,
        };

        const section_count = @divTrunc(world_height, 16);
        var i: u8 = 0;
        while (i < section_count) : (i += 1) {
            const section = try ChunkSection.init(alloc);
            try chunk.sections.put(i, section);
        }

        return chunk;
    }

    pub fn deinit(self: *Chunk, alloc: std.mem.Allocator) void {
        for (self.sections.values()) |*value| value.deinit(alloc);
        self.sections.deinit();

        alloc.destroy(self);
    }

    pub fn setBlock(self: *Chunk, x: u32, y: u32, z: u32, block_id: u16) !bool {
        const section_y = @as(u8, @intCast(y / 16));

        if (self.sections.getPtr(section_y)) |section| {
            return section.setBlock(x, @mod(y, 16), z, block_id);
        } else {
            return false;
        }
    }

    pub fn getHighestBlock(self: *Chunk, x: u32, z: u32) u32 {
        var height: u32 = 0;

        var iterator = self.sections.iterator();
        while (iterator.next()) |section| {
            var y: u32 = 15;
            while (y > 0) : (y -= 1) {
                const block_id = section.value_ptr.getBlock(x, y, z);
                if (block_id != 0 and height < y + section.key_ptr.* * 16) {
                    height = y + section.key_ptr.* * 16;
                }
            }
        }

        return height + 1;
    }
};
