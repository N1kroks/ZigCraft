const std = @import("std");

const CONTINUE_BIT: u8 = 0x80;
const VALUE_MASK: u8 = 0x7F;
const SHIFT_AMOUNT: u5 = 7;

pub const VarInt = struct {
    value: i32,

    pub fn init(value: i32) VarInt {
        return .{ .value = value };
    }

    pub fn write(self: VarInt, writer: anytype) !void {
        var val: u32 = @bitCast(self.value);

        while (val >= CONTINUE_BIT) {
            const byte_to_write = @as(u8, @truncate(val)) | CONTINUE_BIT;
            try writer.writeByte(byte_to_write);
            val >>= SHIFT_AMOUNT;
        }

        try writer.writeByte(@as(u8, @truncate(val)));
    }

    pub fn read(reader: anytype) !VarInt {
        var result: u32 = 0;
        var shift_offset: u5 = 0;

        while (true) {
            const byte = try reader.readByte();
            const data_bits = byte & VALUE_MASK;

            result |= (@as(u32, data_bits) << shift_offset);

            if ((byte & CONTINUE_BIT) == 0) break;

            shift_offset += SHIFT_AMOUNT;
        }

        return VarInt.init(@bitCast(result));
    }
};

pub const String = struct {
    data: []const u8,
    length: VarInt,

    pub fn init(data: []const u8) String {
        return .{
            .data = data,
            .length = VarInt.init(@as(i32, @intCast(data.len))),
        };
    }

    pub fn write(self: String, writer: anytype) !void {
        try self.length.write(writer);
        try writer.writeAll(self.data);
    }

    pub fn read(alloc: std.mem.Allocator, reader: anytype) !String {
        const len = try VarInt.read(reader);
        const buf = try alloc.alloc(u8, @as(usize, @intCast(len.value)));

        for (buf) |*byte_ptr| {
            byte_ptr.* = try reader.readByte();
        }

        return String.init(buf);
    }
};

pub const ByteArray = struct {
    data: []const u8,

    pub fn init(data: []const u8) ByteArray {
        return .{ .data = data };
    }

    pub fn write(self: ByteArray, writer: anytype) !void {
        try writer.writeAll(self.data);
    }

    pub fn read(alloc: std.mem.Allocator, len: usize, reader: anytype) !ByteArray {
        const buf = try alloc.alloc(u8, len);

        for (buf) |*byte_ptr| {
            byte_ptr.* = try reader.readByte();
        }

        return ByteArray.init(buf);
    }
};
