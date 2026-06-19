const std = @import("std");

const epsilon: f32 = 0.00001;

pub const Tuple = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub fn initPoint(x: f32, y: f32, z: f32) Tuple {
        return Tuple{ .x = x, .y = y, .z = z, .w = 1.0 };
    }

    pub fn initVector(x: f32, y: f32, z: f32) Tuple {
        return Tuple{ .x = x, .y = y, .z = z, .w = 0.0 };
    }

    pub fn isPoint(self: *const Tuple) bool {
        return self.w == 1.0;
    }

    pub fn isVector(self: *const Tuple) bool {
        return self.w == 0.0;
    }

    pub fn add(self: *const Tuple, other: *const Tuple) Tuple {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
            .w = self.w + other.w,
        };
    }

    pub fn sub(self: *const Tuple, other: *const Tuple) Tuple {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
            .w = self.w - other.w,
        };
    }

    pub fn negate(self: *const Tuple) Tuple {
        return .{
            .x = -self.x,
            .y = -self.y,
            .z = -self.z,
            .w = -self.w,
        };
    }

    pub fn multiply(self: *const Tuple, val: f32) Tuple {
        return .{
            .x = self.x * val,
            .y = self.y * val,
            .z = self.z * val,
            .w = self.w * val,
        };
    }

    pub fn divide(self: *const Tuple, val: f32) Tuple {
        return .{
            .x = self.x / val,
            .y = self.y / val,
            .z = self.z / val,
            .w = self.w / val,
        };
    }

    pub fn magnitude(self: *const Tuple) f32 {
        return @sqrt(std.math.pow(f32, self.x, 2) + std.math.pow(f32, self.y, 2) + std.math.pow(f32, self.z, 2));
    }

    pub fn normalize(self: *const Tuple) Tuple {
        const m: f32 = self.magnitude();

        return .{
            .x = self.x / m,
            .y = self.y / m,
            .z = self.z / m,
            .w = self.w / m,
        };
    }

    pub fn dot(self: *const Tuple, other: *const Tuple) f32 {
        return self.x * other.x +
            self.y * other.y +
            self.z * other.z +
            self.w * other.w;
    }

    pub fn cross(self: *const Tuple, other: *const Tuple) Tuple {
        return Tuple.initVector(self.y * other.z - self.z * other.y,
                                self.z * other.x - self.x * other.z,
                                self.x * other.y - self.y * other.x);
    }

    pub fn equals(self: *const Tuple, other: *const Tuple) bool {
        if (@abs(self.x - other.x) > epsilon) return false;
        if (@abs(self.y - other.y) > epsilon) return false;
        if (@abs(self.z - other.z) > epsilon) return false;
        if (@abs(self.w - other.w) > epsilon) return false;
        return true;
    }
};

test "a tuple with w=1.0 is a point" {
    const my_point: Tuple = .{
        .x = 4.3,
        .y = -4.2,
        .z = 3.1,
        .w = 1.0,
    };

    try std.testing.expect(my_point.isPoint());
    try std.testing.expect(!my_point.isVector());
}

test "a tuple with w=0.0 is a vector" {
    const my_vec: Tuple = .{
        .x = 4.3,
        .y = -4.2,
        .z = 3.1,
        .w = 0.0,
    };

    try std.testing.expect(!my_vec.isPoint());
    try std.testing.expect(my_vec.isVector());
}

test "initPoint() creates tuples with w=1.0" {
    const p: Tuple = Tuple.initPoint(4, -4, 3);
    const expected_point: Tuple = .{ .x = 4, .y = -4, .z = 3, .w = 1.0 };

    try std.testing.expectEqual(p, expected_point);
    try std.testing.expect(p.equals(&expected_point));
}

test "initVector() creates tuples with w=0.0" {
    const p: Tuple = Tuple.initVector(4, -4, 3);
    const expected_vector: Tuple = .{ .x = 4, .y = -4, .z = 3, .w = 0.0 };

    try std.testing.expectEqual(p, expected_vector);
    try std.testing.expect(p.equals(&expected_vector));
}

test "adding two tuples" {
    const tuple1: Tuple = .{ .x = 3, .y = -2, .z = 5, .w = 1 };
    const tuple2: Tuple = .{ .x = -2, .y = 3, .z = 1, .w = 0 };
    const expected: Tuple = .{ .x = 1, .y = 1, .z = 6, .w = 1 };

    try std.testing.expectEqual(expected, tuple1.add(&tuple2));
}

test "subtracting two points" {
    const tuple1: Tuple = .{ .x = 3, .y = 2, .z = 1, .w = 1 };
    const tuple2: Tuple = .{ .x = 5, .y = 6, .z = 7, .w = 1 };
    const expected: Tuple = .{ .x = -2, .y = -4, .z = -6, .w = 0 };

    try std.testing.expectEqual(expected, tuple1.sub(&tuple2));
    try std.testing.expect(expected.isVector());
}

test "subtracting a vector from a point" {
    const point: Tuple = .{ .x = 3, .y = 2, .z = 1, .w = 1 };
    const vector: Tuple = .{ .x = 5, .y = 6, .z = 7, .w = 0 };
    const expected: Tuple = .{ .x = -2, .y = -4, .z = -6, .w = 1 };

    try std.testing.expectEqual(expected, point.sub(&vector));
    try std.testing.expect(expected.isPoint());
}

test "subtracting two vectors" {
    const vector1: Tuple = .{ .x = 3, .y = 2, .z = 1, .w = 0 };
    const vector2: Tuple = .{ .x = 5, .y = 6, .z = 7, .w = 0 };
    const expected: Tuple = .{ .x = -2, .y = -4, .z = -6, .w = 0 };

    try std.testing.expectEqual(expected, vector1.sub(&vector2));
    try std.testing.expect(expected.isVector());
}

test "subtracting a vector from the zero vector" {
    const zero: Tuple = Tuple.initVector(0, 0, 0);
    const vec: Tuple = Tuple.initVector(1, -2, 3);
    const expected: Tuple = .{ .x = -1, .y = 2, .z = -3, .w = 0 };

    try std.testing.expectEqual(expected, zero.sub(&vec));
}

test "negating a tuple" {
    const a: Tuple = .{ .x = 1, .y = -2, .z = 3, .w = -4 };
    const expected: Tuple = .{ .x = -1, .y = 2, .z = -3, .w = 4 };

    try std.testing.expectEqual(expected, a.negate());
}

test "multiplying a tuple by a scalar" {
    const a: Tuple = .{ .x = 1, .y = -2, .z = 3, .w = -4 };
    const expected: Tuple = .{ .x = 3.5, .y = -7, .z = 10.5, .w = -14 };

    try std.testing.expectEqual(expected, a.multiply(3.5));
}

test "multiplying a tuple by a fraction" {
    const a: Tuple = .{ .x = 1, .y = -2, .z = 3, .w = -4 };
    const expected: Tuple = .{ .x = 0.5, .y = -1, .z = 1.5, .w = -2 };

    try std.testing.expectEqual(expected, a.multiply(0.5));
}

test "dividing a tuple by a scalar" {
    const a: Tuple = .{ .x = 1, .y = -2, .z = 3, .w = -4 };
    const expected: Tuple = .{ .x = 0.5, .y = -1, .z = 1.5, .w = -2 };

    try std.testing.expectEqual(expected, a.divide(2));
}

test "computing the magnitude of vector(1, 0, 0)" {
    const v: Tuple = Tuple.initVector(1, 0, 0);
    const expected: f32 = 1.0;

    try std.testing.expectEqual(expected, v.magnitude());
}

test "computing the magnitude of vector(0, 1, 0)" {
    const v: Tuple = Tuple.initVector(0, 1, 0);
    const expected: f32 = 1.0;

    try std.testing.expectEqual(expected, v.magnitude());
}

test "computing the magnitude of vector(0, 0, 1)" {
    const v: Tuple = Tuple.initVector(0, 0, 1);
    const expected: f32 = 1.0;

    try std.testing.expectEqual(expected, v.magnitude());
}

test "computing the magnitude of vector(1, 2, 3)" {
    const v: Tuple = Tuple.initVector(1, 2, 3);
    const expected: f32 = @sqrt(14);

    try std.testing.expectEqual(expected, v.magnitude());
}

test "computing the magnitude of vector(-1, -2, -3)" {
    const v: Tuple = Tuple.initVector(-1, -2, -3);
    const expected: f32 = @sqrt(14);

    try std.testing.expectEqual(expected, v.magnitude());
}

test "normalizing vector(4, 0, 0) gives (1, 0, 0)" {
    const v: Tuple = Tuple.initVector(4, 0, 0);
    const expected: Tuple = Tuple.initVector(1, 0, 0);

    try std.testing.expectEqual(expected, v.normalize());
}

test "normalizing vector(1, 2, 3)" {
    const v: Tuple = Tuple.initVector(1, 2, 3);
    const expected: Tuple = Tuple.initVector(0.26726, 0.53452, 0.80178);

    try std.testing.expect(expected.equals(&v.normalize()));
}

test "the dot product of two tuples" {
    const a: Tuple = Tuple.initVector(1, 2, 3);
    const b: Tuple = Tuple.initVector(2, 3, 4);
    const expected: f32 = 20;

    try std.testing.expectEqual(expected, a.dot(&b));
}

test "the cross product of two vectors" {
    const a: Tuple = Tuple.initVector(1, 2, 3);
    const b: Tuple = Tuple.initVector(2, 3, 4);

    try std.testing.expectEqual(Tuple.initVector(-1, 2, -1), a.cross(&b));
    try std.testing.expectEqual(Tuple.initVector(1, -2, 1), b.cross(&a));

}
