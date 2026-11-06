const std = @import("std");
const Tuple = @import("tuples.zig").Tuple;

const EPSILON: f32 = 0.00001;


fn FixedMatrix(comptime rows: usize, comptime cols: usize) type {
    return struct {
        const Self = @This();

        data: [rows][cols]f32,

        pub fn init(data: [rows][cols]f32) Self {
            return .{ .data = data };
        }

        pub fn initIdentity() Self {
            var data: [rows][cols]f32 = @splat(@splat(0));

            for (0..rows) |row| {
                data[row][row] = 1;
            }

            return .{ .data = data };
        }

        pub fn get(self: Self, row: usize, col: usize) f32 {
            return self.data[row][col];
        }

        pub fn set(self: *Self, row: usize, col: usize, value: f32) void {
            self.data[row][col] = value;
        }

        pub fn mul(self: Self, other: Self) Self {
            var data: [rows][cols]f32 = @splat(@splat(0));

            for (0..rows) |row| {
                for (0..cols) |col| {
                    for (0..cols) |i| {
                        data[row][col] += self.data[row][i] * other.data[i][col];
                    }
                }
            }

            return .init(data);
        }

        pub fn mulTuple(self: Self, tuple: Tuple) Tuple {
            if (rows != 4 and cols != 4) {
                @compileError("matrix must be of height 4");
            }

            return .init(
                self.data[0][0] * tuple.x + self.data[0][1] * tuple.y + self.data[0][2] * tuple.z + self.data[0][3] * tuple.w,
                self.data[1][0] * tuple.x + self.data[1][1] * tuple.y + self.data[1][2] * tuple.z + self.data[1][3] * tuple.w,
                self.data[2][0] * tuple.x + self.data[2][1] * tuple.y + self.data[2][2] * tuple.z + self.data[2][3] * tuple.w,
                self.data[3][0] * tuple.x + self.data[3][1] * tuple.y + self.data[3][2] * tuple.z + self.data[3][3] * tuple.w,
            );
        }

        pub fn equals(self: Self, other: Self) bool {
            for (self.data, other.data) |self_row, other_row| {
                for (self_row, other_row) |self_entry, other_entry| {
                    if (!std.math.approxEqAbs(f32, self_entry, other_entry, EPSILON)) {
                        return false;
                    }
                }
            }
            return true;
        }

    };
}

const Matrix2 = FixedMatrix(2, 2);
const Matrix3 = FixedMatrix(3, 3);
const Matrix4 = FixedMatrix(4, 4);


test "constructing and inspecting a 4x4 matrix" {
    const m: Matrix4 = .init(.{
        .{1,    2,    3,    4},
        .{5.5,  6.5,  7.5,  8.5},
        .{9,    10,   11,   12},
        .{13.5, 14.5, 15.5, 16.5},
    });

    try std.testing.expectEqual(1, m.data[0][0]);
    try std.testing.expectEqual(4, m.data[0][3]);
    try std.testing.expectEqual(5.5, m.data[1][0]);
    try std.testing.expectEqual(7.5, m.data[1][2]);
    try std.testing.expectEqual(11, m.data[2][2]);
    try std.testing.expectEqual(13.5, m.data[3][0]);
    try std.testing.expectEqual(15.5, m.data[3][2]);
}

test "a 2x2 matrix ought to be representable" {
    const m: Matrix2 = .init(.{
        .{-3, 5},
        .{1,  -2},
    });

    try std.testing.expectEqual(-3, m.data[0][0]);
    try std.testing.expectEqual(5, m.data[0][1]);
    try std.testing.expectEqual(1, m.data[1][0]);
    try std.testing.expectEqual(-2, m.data[1][1]);
}

test "a 3x3 matrix ought to be representable" {
    const m: Matrix3 = .init(.{
        .{-3, 5,  0},
        .{1,  -2, -7},
        .{0,  1,  1},
    });

    try std.testing.expectEqual(-3, m.data[0][0]);
    try std.testing.expectEqual(-2, m.data[1][1]);
    try std.testing.expectEqual(1, m.data[2][2]);
}

test "matrix equality with identical matrices" {
    const m: Matrix2 = .init(.{
        .{0, 1},
        .{2, 3},
    });

    const m1: Matrix2 = .init(.{
        .{0, 1},
        .{2, 3},
    });

    try std.testing.expect(m.equals(m1));
}

test "matrix equality with different matrices" {
    const m: Matrix2 = .init(.{
        .{0, 1},
        .{2, 3},
    });

    const m1: Matrix2 = .init(.{
        .{1, 2},
        .{3, 4},
    });

    try std.testing.expect(!m.equals(m1));
}

test "multiplying two matrices" {
    const m: Matrix2 = .init(.{
        .{1, 2},
        .{5, 6},
    });

    const m1: Matrix2 = .init(.{
        .{-2, 1},
        .{3, 2},
    });

    const result: Matrix2 = m.mul(m1);

    try std.testing.expectEqual(4, result.get(0, 0));
    try std.testing.expectEqual(5, result.get(0, 1));
    try std.testing.expectEqual(8, result.get(1, 0));
    try std.testing.expectEqual(17, result.get(1, 1));
}

test "matrix multiplied by a tuple" {

    const m: Matrix4 = .init(.{
        .{1, 2, 3, 4},
        .{2, 4, 4, 2},
        .{8, 6, 4, 1},
        .{0, 0, 0, 1},
    });

    const b: Tuple = .initPoint(1, 2, 3);

    const actual = m.mulTuple(b);
    try std.testing.expectEqual(18, actual.x);
    try std.testing.expectEqual(24, actual.y);
    try std.testing.expectEqual(33, actual.z);
    try std.testing.expectEqual(1, actual.w);
}

test "multiplying a matrix by the identity matrix" {
    const a: Matrix4 = .init(.{
        .{0, 1, 2, 4},
        .{1, 2, 4, 8},
        .{2, 4, 8, 16},
        .{4, 8, 16, 32},
    });

    const identity: Matrix4 = .initIdentity();
    const result = a.mul(identity);

    try std.testing.expect(a.equals(result));
}

test "multiplying the identity matrix by a tuple" {
    const tuple: Tuple = .init(1, 2, 3, 4);
    const identity: Matrix4 = .initIdentity();
    const result = identity.mulTuple(tuple);

    try std.testing.expect(result.equals(tuple));
}
