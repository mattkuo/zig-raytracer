const std = @import("std");
const Tuple = @import("tuples.zig").Tuple;

const EPSILON: f32 = 0.00001;

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
        return initDefault(allocator, rows, cols, 0.0);
    }

    pub fn initDefault(allocator: std.mem.Allocator, rows: usize, cols: usize, default_val: f32) !Matrix {
        const matrix = try allocator.alloc(f32, rows * cols);
        @memset(matrix, default_val);

        return .{
            .rows = rows,
            .cols = cols,
            .matrix = matrix,
            .allocator = allocator,
        };
    }

    pub fn initFromRows(allocator: std.mem.Allocator, comptime cols: usize, values: []const [cols]f32) !Matrix {
        const data = try allocator.alloc(f32, values.len * cols);

        for (values, 0..) |*row, i| {
            @memcpy(data[i * cols ..][0..cols], row);
        }

        return .{
            .rows = values.len,
            .cols = cols,
            .matrix = data,
            .allocator = allocator,
        };
    }

    pub fn initIdentity(allocator: std.mem.Allocator, size: usize) !Matrix {
        const data = try allocator.alloc(f32, size * size);
        @memset(data, 0);

        for (0..size) |i| {
            data[i * size + i] = 1;
        }

        return .{
            .rows = size,
            .cols = size,
            .matrix = data,
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

        return &self.matrix[self.cols * row + col];
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

    pub fn mulTuple(self: Matrix, tuple: Tuple) !Tuple {
        if (self.rows != 4 or self.cols != 4) {
            return MatrixError.IncompatibleBounds;
        }

        var result: Tuple = undefined;
        const field_names = @typeInfo(Tuple).@"struct".field_names;

        inline for (field_names, 0..) |result_field, row| {
            var sum: f32 = 0;

            inline for (field_names, 0..) |input_field, col| {
                sum += self.matrix[row * self.cols + col] * @field(tuple, input_field);
            }

            @field(result, result_field) = sum;
        }

        return result;
    }

    pub fn equals(self: Matrix, other: Matrix) bool {
        if (self.rows != other.rows or self.cols != other.cols) {
            return false;
        }

        for (self.matrix, 0..) |cell_val, index| {
            if (@abs(cell_val - other.matrix[index]) > EPSILON) {
                return false;
            }
        }

        return true;
    }
};

test "constructing and inspecting a 4x4 matrix" {
    const allocator = std.testing.allocator;

    var m: Matrix = try .initFromRows(allocator, 4, &.{
        .{1,    2,    3,    4},
        .{5.5,  6.5,  7.5,  8.5},
        .{9,    10,   11,   12},
        .{13.5, 14.5, 15.5, 16.5},
    });
    defer m.deinit();

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

test "matrix multiplied by a tuple" {
    const allocator = std.testing.allocator;

    var m: Matrix = try .initFromRows(allocator, 4, &.{
        .{1, 2, 3, 4},
        .{2, 4, 4, 2},
        .{8, 6, 4, 1},
        .{0, 0, 0, 1},
    });
    defer m.deinit();

    const b: Tuple = .initPoint(1, 2, 3);

    const actual = try m.mulTuple(b);
    try std.testing.expectEqual(18, actual.x);
    try std.testing.expectEqual(24, actual.y);
    try std.testing.expectEqual(33, actual.z);
    try std.testing.expectEqual(1, actual.w);
}

test "multiplying a matrix by the identity matrix" {
    const allocator = std.testing.allocator;

    var a: Matrix = try .initFromRows(allocator, 4, &.{
        .{0, 1, 2, 4},
        .{1, 2, 4, 8},
        .{2, 4, 8, 16},
        .{4, 8, 16, 32},
    });
    defer a.deinit();

    var identity: Matrix = try .initIdentity(allocator, 4);
    defer identity.deinit();

    var result = try a.mul(identity);
    defer result.deinit();

    try std.testing.expect(a.equals(result));
}

test "multiplying the identity matrix by a tuple" {
    const allocator = std.testing.allocator;

    const tuple: Tuple = .init(1, 2, 3, 4);

    var identity: Matrix = try .initIdentity(allocator, 4);
    defer identity.deinit();

    const result = try identity.mulTuple(tuple);
    try std.testing.expect(result.equals(tuple));
}
