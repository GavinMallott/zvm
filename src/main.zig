const std = @import("std");
const ZVM = @import("ZVM.zig");
const printf = std.debug.print;

pub fn main() !void {
    var args = try std.process.ArgIterator.initWithAllocator(std.heap.page_allocator);
    defer args.deinit();

    var config: [1024]u8 = undefined;
    var z = ZVM.init();
    
    _ = try z.read_file_if_exists(config[0..]);

    _ = args.next();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "version") or std.mem.eql(u8, arg, "-v")) {
            printf("Active Zig Version: {s}\n", .{z.zvm_version()});
        }
    }
    try z.update_mirrors();
}
