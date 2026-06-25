const std = @import("std");
const Color = @import("tuples.zig").Color;

pub const Canvas = struct {

    width: usize,
    height: usize,
    pixels: []Color,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, width: u32, height: u32) !Canvas {
        const pixels = try allocator.alloc(Color, width * height);

        @memset(pixels, Color{ .r = 0, .g = 0, .b = 0 });
        return .{
            .width = width,
            .height = height,
            .pixels = pixels,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Canvas) void {
        self.allocator.free(self.pixels);
    }

    pub fn write_pixel(self: *Canvas, color: Color, x: u32, y: u32) void {
        self.pixels[y * self.width + x] = color;
    }

    pub fn pixel_at(self: *const Canvas, x: u32, y: u32) Color {
        return self.pixels[y * self.width + x];
    }

};

test "creating a canvas" {
    const allocator = std.testing.allocator;

    var c = try Canvas.init(allocator, 10, 20);
    defer c.deinit();

    const expected: Color = .{ .r = 0, .g = 0, .b = 0 };

    for (c.pixels) |p| {
        try std.testing.expectEqual(expected, p);
    }
}

test "writing pixels to canvas" {
    const allocator = std.testing.allocator;

    var c = try Canvas.init(allocator, 10, 20);
    defer c.deinit();

    const x: u32 = 2;
    const y: u32 = 3;
    const red: Color = .{ .r = 1, .g = 0, .b = 0 };

    c.write_pixel(red, x, y);
    try std.testing.expectEqual(red, c.pixel_at(x, y));
}
