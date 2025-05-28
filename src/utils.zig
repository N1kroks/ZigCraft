pub fn chunkKey(x: i32, z: i32) u64 {
    return (@as(u64, @as(u32, @bitCast(x))) << 32) | @as(u64, @as(u32, @bitCast(z)));
}

pub fn chunkKeyToCoords(key: u64) struct { x: i32, z: i32 } {
    const z = @as(i32, @bitCast(@as(u32, @truncate(key))));
    const x = @as(i32, @bitCast(@as(u32, @truncate(key >> 32))));
    return .{ .x = x, .z = z };
}
