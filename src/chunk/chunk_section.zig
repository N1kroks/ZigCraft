const std = @import("std");

const PackedDataArray = @import("packed_data_array.zig").PackedDataArray;

pub const ChunkSection = struct {
    data: PackedDataArray,
    block_count: u16,

    pub fn init(alloc: std.mem.Allocator) !ChunkSection {
        return ChunkSection{
            .data = try PackedDataArray.init(alloc, 15, 4096),
            .block_count = 0,
        };
    }

    pub fn deinit(self: *ChunkSection, alloc: std.mem.Allocator) void {
        self.data.deinit(alloc);
    }

    pub fn getBlock(self: *ChunkSection, x: u32, y: u32, z: u32) u16 {
        return @intCast(self.data.get(getIndex(x, y, z)));
    }

    pub fn setBlock(self: *ChunkSection, x: u32, y: u32, z: u32, block_id: u16) bool {
        const current_block = self.getBlock(x, y, z);

        if (current_block == 0 and block_id != 0) {
            self.block_count += 1;
        } else if (current_block != 0 and block_id == 0) {
            self.block_count -= 1;
        }

        self.data.set(getIndex(x, y, z), block_id);

        return current_block != block_id;
    }
};

fn getIndex(x: u32, y: u32, z: u32) usize {
    return @as(usize, @intCast((y << 8) | (z << 4) | x));
}
