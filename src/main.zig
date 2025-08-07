const std = @import("std");
const zvm = @import("ZVM.zig");
const printf = std.debug.print;

const CONFIG_FILE = ".zvm.yaml";

pub fn main() !void {
    var args = try std.process.ArgIterator.initWithAllocator(std.heap.page_allocator);
    defer args.deinit();

    var config: [1024]u8 = undefined;
    var z = ZVM.init();
    
    const ff = try z.read_file_if_exists(config[0..]);
    const str = if (ff) "actually" else "not";
    printf("File was {s} found\n", .{str}); 

    _ = args.next();

    printf("Main function sees config: {s}\n", .{z.version});

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "version") or std.mem.eql(u8, arg, "-v")) {
            printf("Active Zig Version: {s}\n", .{z.zvm_version()});
        }
    }
}

pub const ZVM = struct {

    version: []const u8,
    dir: []const u8,

    pub fn init() ZVM {
        return .{
            .version = "0.15.0-dev",
            .dir = "/home/gavin/.zvm",
        };
    }

    pub fn zvm_version(self: *@This()) []const u8 {
        return self.version;
    }

    fn read_file_if_exists(self: *@This(), buf: []u8) !bool {
        var tmp: [1024]u8 = undefined;
        var file = std.fs.cwd().openFile(".zvm.conf", .{}) catch |e| {
            if (e == error.FileNotFound) {
                return false;
            }
            return e;
        };
        defer file.close();

        var FR = file.reader(tmp[0..]);
        const lines = FR.read(buf) catch |e| {
            if (e == error.EndOfStream) {}
            return e;
        };
        const version_str = std.mem.trim(u8, buf[0..lines], "\r\n\t");

        //printf("File: {s}\n With {d} lines\n", .{buf[0..lines], lines});
        if (buf.len > 0) {
            self.version = version_str;
        }
        return true;
    }
};
