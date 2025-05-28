pub const packet = @import("packet/packet.zig");

pub usingnamespace @import("connection_state.zig");

const nbt = @import("../nbt/nbt.zig");

pub const BASIC_REGISTRY_CODEC = nbt.NbtTag{
    .tag_compound = .{
        .identifier = "",
        .children = &[_]nbt.NbtTag{
            .{
                .tag_compound = .{
                    .identifier = "minecraft:chat_type",
                    .children = &[_]nbt.NbtTag{
                        .{
                            .tag_string = .{
                                .identifier = "type",
                                .content = "minecraft:chat_type",
                            },
                        },
                        .{
                            .tag_list = .{
                                .identifier = "value",
                                .elements = &[_]nbt.NbtTag{},
                            },
                        },
                    },
                },
            },
            .{
                .tag_compound = .{
                    .identifier = "minecraft:dimension_type",
                    .children = &[_]nbt.NbtTag{
                        .{
                            .tag_string = .{
                                .identifier = "type",
                                .content = "minecraft:dimension_type",
                            },
                        },
                        .{
                            .tag_list = .{
                                .identifier = "value",
                                .elements = &[_]nbt.NbtTag{
                                    .{
                                        .tag_compound = .{
                                            .identifier = "",
                                            .children = &[_]nbt.NbtTag{
                                                .{
                                                    .tag_string = .{
                                                        .identifier = "name",
                                                        .content = "minecraft:overworld",
                                                    },
                                                },
                                                .{
                                                    .tag_int = .{
                                                        .identifier = "id",
                                                        .value = 0,
                                                    },
                                                },
                                                .{
                                                    .tag_compound = .{
                                                        .identifier = "element",
                                                        .children = &[_]nbt.NbtTag{
                                                            .{
                                                                .tag_byte = .{
                                                                    .identifier = "piglin_safe",
                                                                    .value = 0,
                                                                },
                                                            },
                                                            .{
                                                                .tag_byte = .{
                                                                    .identifier = "natural",
                                                                    .value = 1,
                                                                },
                                                            },
                                                            .{
                                                                .tag_float = .{
                                                                    .identifier = "ambient_light",
                                                                    .value = 0,
                                                                },
                                                            },
                                                            .{
                                                                .tag_string = .{
                                                                    .identifier = "infiniburn",
                                                                    .content = "#minecraft:infiniburn_overworld",
                                                                },
                                                            },
                                                            .{
                                                                .tag_byte = .{
                                                                    .identifier = "respawn_anchor_works",
                                                                    .value = 0,
                                                                },
                                                            },
                                                            .{
                                                                .tag_byte = .{
                                                                    .identifier = "has_skylight",
                                                                    .value = 1,
                                                                },
                                                            },
                                                            .{
                                                                .tag_byte = .{
                                                                    .identifier = "bed_works",
                                                                    .value = 1,
                                                                },
                                                            },
                                                            .{
                                                                .tag_string = .{
                                                                    .identifier = "effects",
                                                                    .content = "minecraft:overworld",
                                                                },
                                                            },
                                                            .{
                                                                .tag_byte = .{
                                                                    .identifier = "has_raids",
                                                                    .value = 1,
                                                                },
                                                            },
                                                            .{
                                                                .tag_int = .{
                                                                    .identifier = "logical_height",
                                                                    .value = 384,
                                                                },
                                                            },
                                                            .{
                                                                .tag_float = .{
                                                                    .identifier = "coordinate_scale",
                                                                    .value = 1.0,
                                                                },
                                                            },
                                                            .{
                                                                .tag_byte = .{
                                                                    .identifier = "ultrawarm",
                                                                    .value = 0,
                                                                },
                                                            },
                                                            .{
                                                                .tag_byte = .{
                                                                    .identifier = "has_ceiling",
                                                                    .value = 0,
                                                                },
                                                            },
                                                            .{
                                                                .tag_int = .{
                                                                    .identifier = "monster_spawn_block_light_limit",
                                                                    .value = 0,
                                                                },
                                                            },
                                                            .{
                                                                .tag_compound = .{
                                                                    .identifier = "monster_spawn_light_level",
                                                                    .children = &[_]nbt.NbtTag{
                                                                        .{
                                                                            .tag_string = .{
                                                                                .identifier = "type",
                                                                                .content = "minecraft:uniform",
                                                                            },
                                                                        },
                                                                        .{
                                                                            .tag_compound = .{
                                                                                .identifier = "value",
                                                                                .children = &[_]nbt.NbtTag{
                                                                                    .{
                                                                                        .tag_int = .{
                                                                                            .identifier = "min_inclusive",
                                                                                            .value = 0,
                                                                                        },
                                                                                    },
                                                                                    .{
                                                                                        .tag_int = .{
                                                                                            .identifier = "max_inclusive",
                                                                                            .value = 7,
                                                                                        },
                                                                                    },
                                                                                },
                                                                            },
                                                                        },
                                                                    },
                                                                },
                                                            },
                                                            .{
                                                                .tag_int = .{
                                                                    .identifier = "height",
                                                                    .value = 384,
                                                                },
                                                            },
                                                            .{
                                                                .tag_int = .{
                                                                    .identifier = "min_y",
                                                                    .value = -64,
                                                                },
                                                            },
                                                        },
                                                    },
                                                },
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
            .{
                .tag_compound = .{
                    .identifier = "minecraft:worldgen/biome",
                    .children = &[_]nbt.NbtTag{
                        .{
                            .tag_string = .{
                                .identifier = "type",
                                .content = "minecraft:worldgen/biome",
                            },
                        },
                        .{
                            .tag_list = .{
                                .identifier = "value",
                                .elements = &[_]nbt.NbtTag{
                                    .{
                                        .tag_compound = .{
                                            .identifier = "",
                                            .children = &[_]nbt.NbtTag{
                                                .{
                                                    .tag_string = .{
                                                        .identifier = "name",
                                                        .content = "minecraft:plains",
                                                    },
                                                },
                                                .{
                                                    .tag_int = .{
                                                        .identifier = "id",
                                                        .value = 0,
                                                    },
                                                },
                                                .{
                                                    .tag_compound = .{
                                                        .identifier = "element",
                                                        .children = &[_]nbt.NbtTag{
                                                            .{
                                                                .tag_string = .{
                                                                    .identifier = "precipitation",
                                                                    .content = "none",
                                                                },
                                                            },
                                                            .{
                                                                .tag_float = .{
                                                                    .identifier = "depth",
                                                                    .value = 0.0,
                                                                },
                                                            },
                                                            .{
                                                                .tag_float = .{
                                                                    .identifier = "temperature",
                                                                    .value = 0.5,
                                                                },
                                                            },
                                                            .{
                                                                .tag_float = .{
                                                                    .identifier = "scale",
                                                                    .value = 0.0,
                                                                },
                                                            },
                                                            .{
                                                                .tag_float = .{
                                                                    .identifier = "downfall",
                                                                    .value = 0.0,
                                                                },
                                                            },
                                                            .{
                                                                .tag_string = .{
                                                                    .identifier = "category",
                                                                    .content = "plains",
                                                                },
                                                            },
                                                            .{
                                                                .tag_compound = .{
                                                                    .identifier = "effects",
                                                                    .children = &[_]nbt.NbtTag{
                                                                        .{
                                                                            .tag_int = .{
                                                                                .identifier = "sky_color",
                                                                                .value = 0x787BFF,
                                                                            },
                                                                        },
                                                                        .{
                                                                            .tag_int = .{
                                                                                .identifier = "water_fog_color",
                                                                                .value = 0x050533,
                                                                            },
                                                                        },
                                                                        .{
                                                                            .tag_int = .{
                                                                                .identifier = "fog_color",
                                                                                .value = 0xC0D8FF,
                                                                            },
                                                                        },
                                                                        .{
                                                                            .tag_int = .{
                                                                                .identifier = "water_color",
                                                                                .value = 0x3F76E4,
                                                                            },
                                                                        },
                                                                    },
                                                                },
                                                            },
                                                        },
                                                    },
                                                },
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    },
};
