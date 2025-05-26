const std = @import("std");

const CONTINUE_BIT: u8 = 0x80;
const VALUE_MASK: u8 = 0x7F;
const SHIFT_AMOUNT: u5 = 7;

pub fn readVarInt(reader: anytype) !i32 {
    var result: u32 = 0;
    var shift_offset: u5 = 0;

    while (true) {
        const byte = try reader.readByte();
        const data_bits = byte & VALUE_MASK;

        result |= (@as(u32, data_bits) << shift_offset);

        if ((byte & CONTINUE_BIT) == 0) break;

        shift_offset += SHIFT_AMOUNT;
    }

    return @bitCast(result);
}

pub fn writeVarInt(writer: anytype, value: i32) !void {
    var val: u32 = @bitCast(value);

    while (val >= CONTINUE_BIT) {
        const byte_to_write = @as(u8, @truncate(val)) | CONTINUE_BIT;
        try writer.writeByte(byte_to_write);
        val >>= SHIFT_AMOUNT;
    }

    try writer.writeByte(@as(u8, @truncate(val)));
}

pub fn writeByteArray(writer: anytype, data: []const u8) !void {
    try writeVarInt(writer, @intCast(data.len));
    try writer.writeAll(data);
}

pub fn readByteArray(alloc: std.mem.Allocator, reader: anytype, length: i32) ![]u8 {
    const byte_count = @as(usize, @intCast(length));
    const buf = try alloc.alloc(u8, byte_count);

    for (buf) |*byte_ptr| {
        byte_ptr.* = try reader.readByte();
    }

    return buf;
}
