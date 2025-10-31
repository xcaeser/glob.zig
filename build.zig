const std = @import("std");

pub fn build(b: *std.Build) void {
    b.reference_trace = 10;

    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("glob", .{
        .root_source_file = b.path("src/glob.zig"),
        .target = target,
        .optimize = optimize,
    });

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);
    run_mod_tests.has_side_effects = true;

    const test_step = b.step("test", "Run glob.zig tests");
    test_step.dependOn(&run_mod_tests.step);

    const docs_step = b.step("docs", "Build the glob.zig library docs");
    const docs_obj = b.addObject(.{
        .name = "glob",
        .root_module = mod,
    });
    const docs = docs_obj.getEmittedDocs();
    docs_step.dependOn(&b.addInstallDirectory(.{
        .source_dir = docs,
        .install_dir = .prefix,
        .install_subdir = "docs",
    }).step);
}
