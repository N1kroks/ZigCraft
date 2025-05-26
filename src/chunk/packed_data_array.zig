const std = @import("std");

pub const PackedDataArray = struct {
    data: []u64,

    elements: usize,
    element_bits: u6,
    elements_per_long: u64,
    mask: u64,

    pub fn init(alloc: std.mem.Allocator, element_bits: u6, elements: usize) !PackedDataArray {
        const elements_per_long = 64 / @as(u64, @intCast(element_bits));

        const data = try alloc.alloc(u64, (elements + @as(usize, @intCast(elements_per_long)) - 1) / @as(usize, @intCast(elements_per_long)));
        @memset(data, 0x00);

        return PackedDataArray{
            .data = data,

            .elements = elements,
            .element_bits = element_bits,
            .elements_per_long = elements_per_long,
            .mask = (@as(u64, 1) << element_bits) - 1,
        };
    }

    pub fn deinit(self: *PackedDataArray, alloc: std.mem.Allocator) void {
        alloc.free(self.data);
    }

    pub fn set(self: *PackedDataArray, index: usize, value: u32) void {
        const pos = index / @as(usize, @intCast(self.elements_per_long));
        const offset = (index - pos * self.elements_per_long) * self.element_bits;

        const mask = ~(self.mask << @as(u6, @intCast(offset)));
        self.data[pos] = (self.data[pos] & mask) | (@as(u64, value) << @as(u6, @intCast(offset)));
    }

    pub fn get(self: *PackedDataArray, index: usize) u32 {
        const pos = index / @as(usize, @intCast(self.elements_per_long));
        const offset = (index - pos * self.elements_per_long) * self.element_bits;

        return @as(u32, @intCast((self.data[pos] >> @as(u6, @intCast(offset))) & self.mask));
    }
};
