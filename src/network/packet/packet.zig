const std = @import("std");

const nbt = @import("../../nbt/nbt.zig");
const types = @import("types.zig");

pub usingnamespace @import("types.zig");

pub usingnamespace @import("handshake.zig");
pub usingnamespace @import("status.zig");
pub usingnamespace @import("login.zig");
pub usingnamespace @import("play.zig");

pub const PacketHeader = struct { length: types.VarInt, id: types.VarInt };

pub const PacketReader = struct {
    alloc: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator) PacketReader {
        return .{ .alloc = alloc };
    }

    pub fn read(self: *PacketReader, reader: anytype, comptime T: type) !T {
        switch (@typeInfo(T)) {
            .bool => return if (try reader.readByte() == 0) false else true,
            .int => {
                return reader.readInt(T, .big);
            },
            .float => {
                const IntType = std.meta.Int(.signed, @bitSizeOf(T));
                return @as(T, @bitCast(try reader.readInt(IntType, .big)));
            },
            .@"struct" => |struct_info| {
                switch (T) {
                    types.VarInt => return types.VarInt.read(reader),
                    types.String => return types.String.read(self.alloc, reader),
                    types.UUID => return types.UUID.read(reader),
                    else => {
                        if (@hasDecl(T, "read")) {
                            return try @field(T, "read")(self.alloc, reader);
                        }
                        var packet: T = undefined;
                        const fields = struct_info.fields;
                        inline for (fields) |field| {
                            @field(packet, field.name) = try self.read(reader, field.type);
                        }
                        return packet;
                    },
                }
            },
            .@"enum" => {
                const int = try types.VarInt.read(reader);
                const enum_val: T = @enumFromInt(int.value);
                return enum_val;
            },
            else => @compileError("Type " ++ @typeName(T) ++ " is not supported for reading!"),
        }
    }
};

pub const PacketWriter = struct {
    alloc: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator) PacketWriter {
        return .{ .alloc = alloc };
    }

    pub fn write(self: *PacketWriter, wr: anytype, value: anytype) !void {
        const T = @TypeOf(value);

        switch (@typeInfo(T)) {
            .bool => try wr.writeByte(if (value) 1 else 0),
            .int => try wr.writeInt(T, value, .big),
            .pointer => |ptr_info| {
                switch (ptr_info.size) {
                    .slice => {
                        for (value) |item| {
                            try self.write(wr, item);
                        }
                    },
                    else => @compileError("Unsupported pointer type: " ++ @typeName(T)),
                }
            },
            .@"struct" => |struct_info| {
                switch (T) {
                    types.VarInt => try value.write(wr),
                    types.String => try value.write(wr),
                    types.UUID => try value.write(wr),
                    else => {
                        var buff: ?std.ArrayList(u8) = null;
                        defer if (buff) |*b| b.deinit();

                        const writer = if (@hasDecl(T, "PacketID")) blk: {
                            buff = std.ArrayList(u8).init(self.alloc);
                            break :blk buff.?.writer().any();
                        } else wr;

                        if (@hasDecl(T, "write")) {
                            try value.write(self.alloc, writer);
                        } else {
                            const fields = struct_info.fields;
                            inline for (fields) |field| {
                                try self.write(writer, @field(value, field.name));
                            }
                        }

                        if (buff) |*b| if (@hasDecl(T, "PacketID")) {
                            const data = try b.toOwnedSlice();

                            const header = PacketHeader{
                                .length = types.VarInt.init(@as(i32, @intCast(data.len)) + 1),
                                .id = types.VarInt.init(@field(T, "PacketID")),
                            };

                            try self.write(wr, header);
                            try wr.writeAll(data);
                        };
                    },
                }
            },
            .@"enum" => {
                try wr.writeByte(@intFromEnum(value));
            },
            .@"union" => {
                switch (T) {
                    nbt.NbtTag => try nbt.serializeTag(wr, value, false),
                    else => @compileError("Unsupported union type: " ++ @typeName(T)),
                }
            },
            else => @compileError("Type " ++ @typeName(T) ++ " is not supported for writing!"),
        }
    }
};
