const std = @import("std");

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

// test "initPoint() creates tuples with w=1.0" {
//     const p: Tuple = Tuple.initPoint(4, -4, 3);


// }
