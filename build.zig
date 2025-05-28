const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "zigcraft",
        .root_source_file = b.path("src/main.zig"),
        .target = b.graph.host,
    });

    const fastnoise = b.addModule("fastnoise", .{
        .root_source_file = b.path("deps/fastnoise.zig"),
    });

    exe.root_module.addImport("fastnoise", fastnoise);

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
