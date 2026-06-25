const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("zig_raytracer", .{
        .root_source_file = b.path("src/lib/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const executables = [_]struct { name: []const u8, src: []const u8 } {
        .{ .name = "main", .src = "src/bin/main.zig" },
        .{ .name = "main2", .src = "src/bin/main2.zig" },
    };

    for (executables) |exe_info| {
        const exe = b.addExecutable(.{
            .name = exe_info.name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(exe_info.src),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "zig_raytracer", .module = mod },
                },
            }),
        });

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        const run_step = b.step(
            b.fmt("run-{s}", .{exe_info.name}),
            b.fmt("Run {s}", .{exe_info.name}),
        );
        run_step.dependOn(&run_cmd.step);
        run_cmd.step.dependOn(b.getInstallStep());
    }

    const mod_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/lib/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // A run step that will run the test executable.
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);

}
