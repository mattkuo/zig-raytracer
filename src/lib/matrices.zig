const std = @import("std");
const Tuple = @import("tuples.zig").Tuple;

const epsilon: f32 = 0.00001;

pub const MatrixError = error {
    IndexOutOfBounds,
    IncompatibleBounds,
};

pub const Matrix = struct {
    rows: usize,
    cols: usize,
    matrix: []f32,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, rows: usize, cols: usize) !Matrix {
        return init_default(allocator, rows, cols, 0.0);
    }

    pub fn init_default(allocator: std.mem.Allocator, rows: usize, cols: usize, default_val: f32) !Matrix {
        const matrix = try allocator.alloc(f32, rows * cols);
        @memset(matrix, default_val);

        return .{
            .rows = rows,
            .cols = cols,
            .matrix = matrix,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Matrix) void {
        self.allocator.free(self.matrix);
    }

    pub fn at(self: *Matrix, row: usize, col: usize) !*f32 {
        if (row >= self.rows or col >= self.cols) {
            return MatrixError.IndexOutOfBounds;
        }

        return &self.matrix[self.rows * row + col];
    }

    pub fn mul(self: Matrix, other: Matrix) !Matrix {
        if (self.cols != other.rows) {
            return MatrixError.IncompatibleBounds;
        }

        const result: Matrix = try .init(self.allocator, self.rows, other.cols);
        for (0..self.rows) |row| {
            for (0..other.cols) |col| {
                var sum: f32 = 0;
                for (0..self.cols) |k| {
                    sum += self.matrix[row * self.cols + k] * other.matrix[k * other.cols + col];
                }
                result.matrix[row * other.cols + col] = sum;
            }
        }
        return result;
    }

    pub fn mul_tuple(self: Matrix, tuple: Tuple) Tuple {
        const result: Tuple = .{ .x = 0, .y = 0, .z = 0, .w = 0 };
        for (0..self.rows) |row| {
            var sum: f32 = 0;
            for (0..self.cols) |col| {
                inline for (std.meta.fields(@TypeOf(tuple))) |field| {
                    sum += self.matrix[self.rows * row + col] * @field(tuple, field);
                }
            }
            @field(result, std.meta.fields(@TypeOf(tuple))[row]) = sum;
        }

        return result;
    }

    pub fn equals(self: Matrix, other: Matrix) bool {
        if (self.rows != other.rows or self.cols != other.cols) {
            return false;
        }

        for (self.matrix, 0..) |cell_val, index| {
            if (@abs(cell_val - other.matrix[index]) > epsilon) {
                return false;
            }
        }

        return true;
    }
};

test "constructing and inspecting a 4x4 matrix" {
    const allocator = std.testing.allocator;

    var m: Matrix = try .init(allocator, 4, 4);
    defer m.deinit();
    (try m.at(0, 0)).* = 1;
    (try m.at(0, 1)).* = 2;
    (try m.at(0, 2)).* = 3;
    (try m.at(0, 3)).* = 4;

    (try m.at(1, 0)).* = 5.5;
    (try m.at(1, 1)).* = 6.5;
    (try m.at(1, 2)).* = 7.5;
    (try m.at(1, 3)).* = 8.5;

    (try m.at(2, 0)).* = 9;
    (try m.at(2, 1)).* = 10;
    (try m.at(2, 2)).* = 11;
    (try m.at(2, 3)).* = 12;

    (try m.at(3, 0)).* = 13.5;
    (try m.at(3, 1)).* = 14.5;
    (try m.at(3, 2)).* = 15.5;
    (try m.at(3, 3)).* = 16.5;

    try std.testing.expect((try m.at(0, 0)).* == 1);
    try std.testing.expect((try m.at(0, 3)).* == 4);
    try std.testing.expect((try m.at(1, 0)).* == 5.5);
    try std.testing.expect((try m.at(1, 2)).* == 7.5);
    try std.testing.expect((try m.at(2, 2)).* == 11);
    try std.testing.expect((try m.at(3, 0)).* == 13.5);
    try std.testing.expect((try m.at(3, 2)).* == 15.5);
}

test "a 2x2 matrix ought to be representable" {
    const allocator = std.testing.allocator;

    var m: Matrix = try .init(allocator, 2, 2);
    defer m.deinit();
    (try m.at(0, 0)).* = -3;
    (try m.at(0, 1)).* = 5;
    (try m.at(1, 0)).* = 1;
    (try m.at(1, 1)).* = -2;

    try std.testing.expect((try m.at(0, 0)).* == -3);
    try std.testing.expect((try m.at(0, 1)).* == 5);
    try std.testing.expect((try m.at(1, 0)).* == 1);
    try std.testing.expect((try m.at(1, 1)).* == -2);
}

test "a 3x3 matrix ought to be representable" {

    const allocator = std.testing.allocator;

    var m: Matrix = try .init(allocator, 3, 3);
    defer m.deinit();
    (try m.at(0, 0)).* = -3;
    (try m.at(0, 1)).* = 5;

    (try m.at(1, 0)).* = 1;
    (try m.at(1, 1)).* = -2;
    (try m.at(1, 2)).* = -7;

    (try m.at(2, 1)).* = 1;
    (try m.at(2, 2)).* = 1;

    try std.testing.expect((try m.at(0, 0)).* == -3);
    try std.testing.expect((try m.at(1, 1)).* == -2);
    try std.testing.expect((try m.at(2, 2)).* == 1);
}

test "matrix equality with identical matrices" {
    const allocator = std.testing.allocator;

    var m: Matrix = try .init(allocator, 2, 2);
    defer m.deinit();
    (try m.at(0, 0)).* = 0;
    (try m.at(0, 1)).* = 1;
    (try m.at(1, 0)).* = 2;
    (try m.at(1, 1)).* = 3;

    var m1: Matrix = try .init(allocator, 2, 2);
    defer m1.deinit();
    (try m1.at(0, 0)).* = 0;
    (try m1.at(0, 1)).* = 1;
    (try m1.at(1, 0)).* = 2;
    (try m1.at(1, 1)).* = 3;

    try std.testing.expect(m.equals(m1));
}

test "matrix equality with different matrices" {
    const allocator = std.testing.allocator;

    var m: Matrix = try .init(allocator, 2, 2);
    defer m.deinit();
    (try m.at(0, 0)).* = 0;
    (try m.at(0, 1)).* = 1;
    (try m.at(1, 0)).* = 2;
    (try m.at(1, 1)).* = 3;

    var m1: Matrix = try .init(allocator, 2, 2);
    defer m1.deinit();
    (try m1.at(0, 0)).* = 4;
    (try m1.at(0, 1)).* = 5;
    (try m1.at(1, 0)).* = 6;
    (try m1.at(1, 1)).* = 7;

    try std.testing.expect(!m.equals(m1));
}

test "multiplying two matrices" {
    const allocator = std.testing.allocator;

    var m: Matrix = try .init(allocator, 2, 2);
    defer m.deinit();
    (try m.at(0, 0)).* = 1;
    (try m.at(0, 1)).* = 2;
    (try m.at(1, 0)).* = 5;
    (try m.at(1, 1)).* = 6;

    var m1: Matrix = try .init(allocator, 2, 2);
    defer m1.deinit();
    (try m1.at(0, 0)).* = -2;
    (try m1.at(0, 1)).* = 1;
    (try m1.at(1, 0)).* = 3;
    (try m1.at(1, 1)).* = 2;

    var result: Matrix = try m.mul(m1);
    defer result.deinit();

    try std.testing.expectEqual(4, (try result.at(0, 0)).*);
    try std.testing.expectEqual(5, (try result.at(0, 1)).*);
    try std.testing.expectEqual(8, (try result.at(1, 0)).*);
    try std.testing.expectEqual(17, (try result.at(1, 1)).*);
}
