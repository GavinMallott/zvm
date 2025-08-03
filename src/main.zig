const std = @import("std");
const printf = std.debug.print;

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);

    for (args, 0..) |arg, i| {
        printf("Arg{d}: {s}\n", .{i, arg.ptr});
    }
}
