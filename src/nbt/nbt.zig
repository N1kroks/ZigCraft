const std = @import("std");

const TagType = enum(u8) {
    tag_end = 0,
    tag_byte = 1,
    tag_short = 2,
    tag_int = 3,
    tag_long = 4,
    tag_float = 5,
    tag_double = 6,
    tag_byte_array = 7,
    tag_string = 8,
    tag_list = 9,
    tag_compound = 10,
    tag_int_array = 11,
    tag_long_array = 12,
};

pub const NbtTag = union(TagType) {
    tag_end: void,
    tag_byte: ByteTag,
    tag_short: ShortTag,
    tag_int: IntTag,
    tag_long: LongTag,
    tag_float: FloatTag,
    tag_double: DoubleTag,
    tag_byte_array: ByteArrayTag,
    tag_string: StringTag,
    tag_list: ListTag,
    tag_compound: CompoundTag,
    tag_int_array: IntArrayTag,
    tag_long_array: LongArrayTag,

    const ByteTag = struct { identifier: []const u8, value: i8 };
    const ShortTag = struct { identifier: []const u8, value: i16 };
    const IntTag = struct { identifier: []const u8, value: i32 };
    const LongTag = struct { identifier: []const u8, value: i64 };
    const FloatTag = struct { identifier: []const u8, value: f32 };
    const DoubleTag = struct { identifier: []const u8, value: f64 };
    const ByteArrayTag = struct { identifier: []const u8, data: []const u8 };
    const StringTag = struct { identifier: []const u8, content: []const u8 };
    const ListTag = struct { identifier: []const u8, elements: []const NbtTag };
    const CompoundTag = struct { identifier: []const u8, children: []const NbtTag };
    const IntArrayTag = struct { identifier: []const u8, values: []i32 };
    const LongArrayTag = struct { identifier: []const u8, values: []i64 };
};

pub fn serializeTag(writer: anytype, tag: NbtTag, payload_only: bool) !void {
    switch (tag) {
        .tag_end => {
            if (!payload_only) {
                try writer.writeByte(@intFromEnum(TagType.tag_end));
            }
        },
        .tag_byte => |data| {
            if (!payload_only) {
                try writer.writeByte(@intFromEnum(TagType.tag_byte));
                try writeString(writer, data.identifier);
            }
            try writer.writeByte(@bitCast(data.value));
        },
        .tag_short => |data| {
            if (!payload_only) {
                try writer.writeByte(@intFromEnum(TagType.tag_short));
                try writeString(writer, data.identifier);
            }
            try writer.writeInt(i16, data.value, .big);
        },
        .tag_int => |data| {
            if (!payload_only) {
                try writer.writeByte(@intFromEnum(TagType.tag_int));
                try writeString(writer, data.identifier);
            }
            try writer.writeInt(i32, data.value, .big);
        },
        .tag_long => |data| {
            if (!payload_only) {
                try writer.writeByte(@intFromEnum(TagType.tag_long));
                try writeString(writer, data.identifier);
            }
            try writer.writeInt(i64, data.value, .big);
        },
        .tag_float => |data| {
            if (!payload_only) {
                try writer.writeByte(@intFromEnum(TagType.tag_float));
                try writeString(writer, data.identifier);
            }
            const float_bits: u32 = @bitCast(data.value);
            try writer.writeInt(u32, float_bits, .big);
        },
        .tag_double => |data| {
            if (!payload_only) {
                try writer.writeByte(@intFromEnum(TagType.tag_double));
                try writeString(writer, data.identifier);
            }
            const double_bits: u64 = @bitCast(data.value);
            try writer.writeInt(u64, double_bits, .big);
        },
        .tag_byte_array => |data| {
            if (!payload_only) {
                try writer.writeByte(@intFromEnum(TagType.tag_byte_array));
                try writeString(writer, data.identifier);
            }
            try writeArrayLength(writer, data.data.len);
            try writer.writeAll(data.data);
        },
        .tag_string => |data| {
            if (!payload_only) {
                try writer.writeByte(@intFromEnum(TagType.tag_string));
                try writeString(writer, data.identifier);
            }
            try writeString(writer, data.content);
        },
        .tag_list => |data| {
            if (!payload_only) {
                try writer.writeByte(@intFromEnum(TagType.tag_list));
                try writeString(writer, data.identifier);
            }
            if (data.elements.len == 0) {
                try writer.writeByte(@intFromEnum(TagType.tag_end));
                try writeArrayLength(writer, 0);
            } else {
                const element_type = @intFromEnum(data.elements[0]);
                try writer.writeByte(element_type);
                try writeArrayLength(writer, data.elements.len);

                for (data.elements) |item| {
                    try serializeTag(writer, item, true);
                }
            }
        },
        .tag_compound => |data| {
            if (!payload_only) {
                try writer.writeByte(@intFromEnum(TagType.tag_compound));
                try writeString(writer, data.identifier);
            }
            for (data.children) |child_tag| {
                try serializeTag(writer, child_tag, false);
            }
            try serializeTag(writer, .tag_end, false);
        },
        .tag_int_array => |data| {
            if (!payload_only) {
                try writer.writeByte(@intFromEnum(TagType.tag_int_array));
                try writeString(writer, data.identifier);
            }
            try writeArrayLength(writer, data.values.len);
            for (data.values) |int_value| {
                try writer.writeInt(i32, int_value, .big);
            }
        },
        .tag_long_array => |data| {
            if (!payload_only) {
                try writer.writeByte(@intFromEnum(TagType.tag_long_array));
                try writeString(writer, data.identifier);
            }
            try writeArrayLength(writer, data.values.len);
            for (data.values) |long_value| {
                try writer.writeInt(i64, long_value, .big);
            }
        },
    }
}

fn writeString(writer: anytype, string_data: []const u8) !void {
    try writer.writeInt(u16, @as(u16, @intCast(string_data.len)), .big);
    try writer.writeAll(string_data);
}

fn writeArrayLength(writer: anytype, length: usize) !void {
    const len_i32: i32 = @intCast(length);
    try writer.writeInt(i32, len_i32, .big);
}
