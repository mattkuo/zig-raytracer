const std = @import("std");

const Color = @import("tuples.zig").Color;

const clamping_value: u32 = 255;
const ppm_line_len: u32 = 70;

pub const CanvasError = error{
    OutOfBounds,
};

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

    pub fn write_pixel(self: *Canvas, color: Color, x: usize, y: usize) !void {
        if (x >= self.width or y >= self.height) {
            return CanvasError.OutOfBounds;
        }
        self.pixels[y * self.width + x] = color;
    }

    pub fn pixel_at(self: *const Canvas, x: usize, y: usize) !Color {
        if (x >= self.width or y >= self.height) {
            return CanvasError.OutOfBounds;
        }
        return self.pixels[y * self.width + x];
    }

    pub fn to_ppm(self: *const Canvas, allocator: std.mem.Allocator) ![]u8 {
        var buf = std.ArrayList(u8).empty;
        errdefer buf.deinit(allocator);

        // Format header
        try buf.appendSlice(allocator, "P3\n");
        try buf.print(allocator, "{} {}\n", .{self.width, self.height});
        try buf.print(allocator, "{}\n", .{clamping_value});

        for (0..self.height) |y| {
            // count of how many characters we've written on the current line
            var line_width: usize = 0;

            for (0..self.width) |x| {
                const pixel_color = try self.pixel_at(x, y);

                inline for (std.meta.fields(Color)) |field| {
                    const clamped = std.math.clamp(@field(pixel_color, field.name), 0.0, 1.0);
                    const clamped_val: u32 = @intFromFloat(@round(clamped * 255.0));

                    const string_val = try std.fmt.allocPrint(allocator, "{}", .{clamped_val});
                    defer allocator.free(string_val);

                    // if we can't write len of string (+1 more for space) then we want to
                    // start a new line
                    if (line_width + string_val.len + 1 > ppm_line_len) {
                        try buf.append(allocator, '\n');
                        line_width = 0;
                    }

                    // prepend space character if this is not a new line
                    if (line_width != 0) {
                        try buf.append(allocator, ' ');
                        line_width += 1;
                    }

                    try buf.appendSlice(allocator, string_val);
                    line_width += string_val.len;
                }
            }
            try buf.appendSlice(allocator, "\n");
        }

        // Ending newline for picky editors
        try buf.appendSlice(allocator, "\n");
        return buf.toOwnedSlice(allocator);
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

    try c.write_pixel(red, x, y);
    try std.testing.expectEqual(red, c.pixel_at(x, y));
}

test "constructing the PPM header" {
    const allocator = std.testing.allocator;

    var c = try Canvas.init(allocator, 5, 3);
    defer c.deinit();

    const expected: []const u8 = "P3\n5 3\n255\n";
    const ppm = try c.to_ppm(allocator);
    defer allocator.free(ppm);

    var exp_iterator = std.mem.splitSequence(u8, expected, "\n");
    var iterator = std.mem.splitSequence(u8, ppm, "\n");

    for (0..3) |_| {
        const exp = exp_iterator.next().?;
        const current = iterator.next().?;

        try std.testing.expect(std.mem.eql(u8, exp, current));
    }
}

test "constructing the PPM pixel data" {
    const allocator = std.testing.allocator;

    var c = try Canvas.init(allocator, 5, 3);
    defer c.deinit();

    const c1: Color = .{ .r = 1.5, .g = 0, .b = 0 };
    const c2: Color = .{ .r = 0, .g = 0.5, .b = 0 };
    const c3: Color = .{ .r = -0.5, .g = 0, .b = 1 };
    const expected: []const u8 =
        \\255 0 0 0 0 0 0 0 0 0 0 0 0 0 0
        \\0 0 0 0 0 0 0 128 0 0 0 0 0 0 0
        \\0 0 0 0 0 0 0 0 0 0 0 0 0 0 255
    ;

    try c.write_pixel(c1, 0, 0);
    try c.write_pixel(c2, 2, 1);
    try c.write_pixel(c3, 4, 2);

    const result = try c.to_ppm(allocator);
    defer allocator.free(result);

    var exp_iterator = std.mem.splitSequence(u8, expected, "\n");
    var iterator = std.mem.splitSequence(u8, result, "\n");

    // seek past the header
    for (0..3) |_| {
        _ = iterator.next();
    }

    for (0..3) |_| {
        const exp = exp_iterator.next().?;
        const current = iterator.next().?;

        try std.testing.expect(std.mem.eql(u8, exp, current));
    }
}

test "splitting long lines in PPM files" {
    const allocator = std.testing.allocator;

    var c = try Canvas.init(allocator, 10, 2);
    defer c.deinit();

    const color: Color = .{ .r = 1, .g = 0.8, .b = 0.6 };
    const expected: []const u8 =
        \\255 204 153 255 204 153 255 204 153 255 204 153 255 204 153 255 204
        \\153 255 204 153 255 204 153 255 204 153 255 204 153
        \\255 204 153 255 204 153 255 204 153 255 204 153 255 204 153 255 204
        \\153 255 204 153 255 204 153 255 204 153 255 204 153
    ;

    for (0..c.height) |y| {
        for (0..c.width) |x| {
            try c.write_pixel(color, x, y);
        }
    }

    const result = try c.to_ppm(allocator);
    defer allocator.free(result);

    var exp_iterator = std.mem.splitSequence(u8, expected, "\n");
    var iterator = std.mem.splitSequence(u8, result, "\n");

    // seek past the header
    for (0..3) |_| {
        _ = iterator.next();
    }

    for (0..4) |_| {
        const exp = exp_iterator.next().?;
        const current = iterator.next().?;

        try std.testing.expect(std.mem.eql(u8, exp, current));
    }
}

test "PPM files are terminated by a newline character" {
    const allocator = std.testing.allocator;

    var c = try Canvas.init(allocator, 5, 3);
    defer c.deinit();

    const result = try c.to_ppm(allocator);
    defer allocator.free(result);

    try std.testing.expect(result[result.len - 1] == '\n');
}
