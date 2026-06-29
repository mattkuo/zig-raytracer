const std = @import("std");

const epsilon: f32 = 0.00001;

pub const MatrixError = error {
    IndexOutOfBounds,
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
