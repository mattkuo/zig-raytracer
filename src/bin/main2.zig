const std = @import("std");
const Io = std.Io;

const zig_raytracer = @import("zig_raytracer");
const Tuple = zig_raytracer.tuples.Tuple;
const Color = zig_raytracer.tuples.Color;
const Canvas = zig_raytracer.canvas.Canvas;

const Environment = struct {
    gravity: Tuple,
    wind: Tuple,
};

const Projectile = struct {
    position: Tuple,
    velocity: Tuple,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var p = Projectile{
        .position = Tuple.initPoint(0, 1, 0),
        .velocity = Tuple.initVector(1, 1, 0).normalize().mul(11.25),
    };

    const e = Environment{
        .gravity = Tuple.initVector(0, -0.1, 0),
        .wind = Tuple.initVector(-0.01, 0, 0),
    };

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var canvas: Canvas = try Canvas.init(allocator, 900, 550);
    const project_color: Color = .{ .r = 1, .g = 0, .b = 0 };

    while (p.position.y > 0) {
        p = tick(e, p);
        const new_x: usize = @intFromFloat(p.position.x);
        const new_y: usize = @intFromFloat(550.0 - p.position.y);

        if (new_x < 0 or new_x > 900 or new_y < 0 or new_y > 550) {
            continue;
        }

        canvas.write_pixel(project_color, new_x, new_y) catch |err| {
            std.debug.print("Error: {}\n", .{err});
        };
    }

    const ppm = try canvas.to_ppm(allocator);
    defer allocator.free(ppm);

    const f = try std.Io.Dir.createFileAbsolute(io, "/tmp/chapter2.ppm", .{});
    defer f.close(io);

    var writer = f.writer(io, &.{});

    const bytes = try writer.interface.write(ppm);
    std.debug.print("Wrote {d} bytes \n", .{bytes});
}

fn tick(env: Environment, projectile: Projectile) Projectile {
    const pos = projectile.position.add(projectile.velocity);
    const velocity = projectile.velocity
        .add(env.gravity)
        .add(env.wind);

    return .{ .position = pos, .velocity = velocity };
}
