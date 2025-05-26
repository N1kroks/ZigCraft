const std = @import("std");
const Server = @import("server.zig").Server;

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();

    std.debug.print("Server is staring\n", .{});

    var server = try Server.init(gpa.allocator(), try std.net.Address.parseIp("0.0.0.0", 25565));
    defer server.deinit();

    try server.start();
}
