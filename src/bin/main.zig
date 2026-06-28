const std = @import("std");
const Io = std.Io;

const zig_raytracer = @import("zig_raytracer");
const Tuple = zig_raytracer.tuples.Tuple;

const Environment = struct {
    gravity: Tuple,
    wind: Tuple,
};

const Projectile = struct {
    position: Tuple,
    velocity: Tuple,
};

pub fn main() !void {
    var p = Projectile{
        .position = Tuple.initPoint(0, 1, 0),
        .velocity = Tuple.initVector(1, 1, 0).normalize(),
    };

    const e = Environment{
        .gravity = Tuple.initVector(0, -0.1, 0),
        .wind = Tuple.initVector(-0.01, 0, 0),
    };

    while (p.position.y > 0) {
        p = tick(e, p);
        std.debug.print("Projectile position: {any}\n", .{p.position});
    }
}

fn tick(env: Environment, projectile: Projectile) Projectile {
    const pos = projectile.position.add(projectile.velocity);
    const velocity = projectile.velocity
        .add(env.gravity)
        .add(env.wind);

    return .{ .position = pos, .velocity = velocity };
}
