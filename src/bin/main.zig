const std = @import("std");
const Io = std.Io;

const zig_raytracer = @import("zig_raytracer");

pub fn main() !void {
    // Prints to stderr, unbuffered, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    _ = zig_raytracer.tuples.Tuple.initVector(0, 0, 0);
}
