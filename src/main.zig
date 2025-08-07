const std = @import("std");
const c = @cImport({
    @cInclude("curl/curl.h");
});


const printf = std.debug.print;


pub const ZIG_PUB_KEY = "RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U";
pub const MIRRORS = [_][]const u8{"none", "one"};
pub const CONFIG_FILE = ".zvm.zon";


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
    z.update_mirrors();
}


pub const ZVM = struct {
    version: []const u8,
    dir: []const u8,
    mirrors: []const []const u8,

    pub fn init() ZVM {
        return .{
            .version = "0.15.0-dev",
            .dir = "/home/gavin/.zvm",
            .mirrors = MIRRORS[0..],
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

    fn update_mirrors(self: *@This()) void {

        printf("Mirrors:\n", .{});
        for (self.mirrors) |mirror| {
            printf(" - {s}\n", .{mirror});
        }
    }
};
