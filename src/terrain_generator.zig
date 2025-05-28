const std = @import("std");

const fastnoise = @import("fastnoise");
const Chunk = @import("chunk/chunk.zig").Chunk;

const NoiseOctaveSettings = struct {
    noise_type: fastnoise.NoiseType,
    frequency: f32,
    amplitude: f32,
};

const Octaves: []const NoiseOctaveSettings = &[_]NoiseOctaveSettings{
    .{ .noise_type = .simplex, .frequency = 0.2, .amplitude = 0.6 },
    .{ .noise_type = .simplex, .frequency = 0.04, .amplitude = 6 },
    .{ .noise_type = .simplex, .frequency = 0.008, .amplitude = 15 },
};

const DomainWarp: NoiseOctaveSettings = .{ .noise_type = .simplex, .frequency = 0.06, .amplitude = 15 };

pub const TerrainGenerator = struct {
    alloc: std.mem.Allocator,

    octave_noises: []fastnoise.Noise(f32),

    warp_noise: fastnoise.Noise(f32),

    pub fn init(alloc: std.mem.Allocator) !TerrainGenerator {
        const noises = try alloc.alloc(fastnoise.Noise(f32), Octaves.len);

        for (noises, 0..) |*noise, i| {
            const octave = Octaves[i];

            noise.* = fastnoise.Noise(f32){ .noise_type = octave.noise_type, .frequency = octave.frequency };
        }

        const warp_noise = fastnoise.Noise(f32){ .noise_type = DomainWarp.noise_type, .frequency = DomainWarp.frequency, .domain_warp_amp = DomainWarp.amplitude };

        return .{
            .alloc = alloc,
            .octave_noises = noises,
            .warp_noise = warp_noise,
        };
    }

    pub fn deinit(self: *TerrainGenerator) void {
        self.alloc.free(self.octave_noises);
    }

    fn getHeight(self: *TerrainGenerator, x: i32, z: i32) i32 {
        var result: f32 = 128; // Base height

        var fx = @as(f32, @floatFromInt(x));
        var fz = @as(f32, @floatFromInt(z));
        self.warp_noise.domainWarp2D(&fx, &fz);

        for (self.octave_noises, 0..) |*noise, i| {
            const noise_value = noise.genNoise2D(fx, fz);
            result += noise_value * Octaves[i].amplitude / 2;
        }

        return @as(i32, @intFromFloat(@round(result)));
    }

    pub fn generateTerrain(self: *TerrainGenerator, chunk: *Chunk) !void {
        var cx: u32 = 0;
        while (cx < 16) : (cx += 1) {
            var cz: u32 = 0;
            while (cz < 16) : (cz += 1) {
                var cy: u32 = 0;
                const height = self.getHeight((chunk.x * 16) + @as(i32, @intCast(cx)), (chunk.z * 16) + @as(i32, @intCast(cz)));
                while (cy < height) : (cy += 1) {
                    _ = try chunk.setBlock(cx, cy, cz, if (cy == height - 1) 9 else 10);
                }
            }
        }
    }
};
