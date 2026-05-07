const std = @import("std");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .linkage = .dynamic,
    });

    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    // Web exports are completely separate.
    if (target.query.os_tag == .emscripten) {
        const wasm = b.addLibrary(.{
            .name = "type-train",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .optimize = optimize,
                .target = target,
            }),
        });
        wasm.root_module.addImport("raylib", raylib);

        const install_dir: std.Build.InstallDir = .{ .custom = "web" };
        const emcc_flags = rlz.emsdk.emccDefaultFlags(b.allocator, .{
            .optimize = optimize,
        });
        const emcc_settings = rlz.emsdk.emccDefaultSettings(b.allocator, .{
            .optimize = optimize,
        });

        const emcc_step = rlz.emsdk.emccStep(b, raylib_artifact, wasm, .{
            .optimize = optimize,
            .flags = emcc_flags,
            .settings = emcc_settings,
            .shell_file_path = rlz.emsdk.shell(b),
            .install_dir = install_dir,
            .embed_paths = &.{.{ .src_path = "resources/" }},
        });

        const html_filename = try std.fmt.allocPrint(b.allocator, "{s}.html", .{wasm.name});
        const run_step = rlz.emsdk.emrunStep(
            b,
            b.getInstallPath(install_dir, html_filename),
            &.{},
        );
        run_step.dependOn(emcc_step);
        const run_option = b.step("run", "Run type-train");
        run_option.dependOn(run_step);
        return;
    }

    const exe = b.addExecutable(.{
        .name = "type-train",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .optimize = optimize,
            .target = target,
        }),
    });

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run type-train");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);
}
