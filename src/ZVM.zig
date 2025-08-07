const std = @import("std");

zig_version: []const u8,
zig_dir: []const u8,

pub const ZVM = @This();

pub fn zvm_version(self: *ZVM) []const u8 {
    return self.zig_version;
}
