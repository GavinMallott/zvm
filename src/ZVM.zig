const std = @import("std");
const util = @import("util.zig");
const printf = std.debug.print;
const JsonOptions = util.JsonOptions;


version: []const u8,
dir: []const u8,
mirrors: []const []const u8,

pub const ZVM = @This();

const ZIG_PUB_KEY = "RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U";
const MIRRORS = "https://ziglang.org/download/community-mirrors.txt";
const CONFIG_FILE = ".zvm.zon";

pub fn init() ZVM {
    return .{
        .version = "0.15.0-dev",
        .dir = "/home/gavin/.zvm",
        .mirrors = undefined,
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

pub fn update_mirrors(self: *@This()) !void {
    const uri = try std.Uri.parse(MIRRORS);
    var buf: [1024]u8 = undefined;
    var buf_list: [1024][]const u8 = undefined;

    const n = try util.read_uri_into_buffer(uri, buf[0..]);
    
    var lines = std.mem.tokenizeAny(u8, buf[0..n], "\r\n"); 
    var line_idx: usize = 0; 

    while(lines.next()) |line| : (line_idx += 1){
        if (line.len > 0) {
            buf_list[line_idx] = line;
        } else break;
    }

    self.mirrors = buf_list[0..line_idx];

    printf("Mirrors:\n", .{});
    for (self.mirrors) |mirror| {
        printf(" - {s}\n", .{mirror});
    }
}

pub fn zvm_version_list(self: *ZVM) !void {
    _ = self;
    const ally = std.heap.page_allocator;

    const jsonfile = try std.fs.cwd().openFile("index.json", .{});
    defer jsonfile.close();

    const jsondata = try jsonfile.readToEndAlloc(ally, std.math.maxInt(u32));
    defer ally.free(jsondata);

    const parsed = try std.json.parseFromSlice(std.json.Value, ally, jsondata, .{});
    defer parsed.deinit();

    var root_it = parsed.value.object.iterator();

    printf("Available Zig Versions:\n", .{});
    while(root_it.next()) |pair| {
        printf(" - {s}\n", .{pair.key_ptr.*});
    }
    
}

pub fn update_index_json(self: *ZVM, uri: std.Uri, ally: std.mem.Allocator) !void {
    _ = self;
    _ = try util.read_uri_into_file(uri, "index.json", ally);
}

pub fn zvm_download_tarball(self: *ZVM, ally: std.mem.Allocator, opt: JsonOptions) !void {
    _ = self;

    printf("Looking for zig version {s} for {s}-{s}.\n", .{opt.version, opt.arch, opt.os});

    const version_url = try util.select_zig_url_from_json("index.json", ally, opt);
    defer ally.free(version_url);
    
    const version_uri = try std.Uri.parse(version_url);
    printf("Version Found.\n", .{});
    printf("Downloading from {s}.\n", .{version_url});

    var tmp: [128]u8 = undefined;
    const dest = try std.fmt.bufPrint(tmp[0..], "zig-{s}-{s}-{s}.tar.xz", .{opt.os, opt.arch, opt.version});
    _ = try util.read_uri_into_file(version_uri, dest, ally);
    printf("Tarball {s} successfully downloaded.\n", .{dest});

}

pub fn zvm_install_tarball(self: *ZVM, path: []const u8, ally: std.mem.Allocator) !void {
    _ = self;
    printf("Unpacking tarball: {s}.\n", .{path});
    const argv = [_][]const u8 {
        "tar",
        "-xvf",
        path,
    };
    try subprocess_call(&argv, ally);
    printf("Successfully Installed New Zig Version!\n", .{});
}

fn subprocess_call(argv: []const []const u8, ally: std.mem.Allocator) !void {
    var child = std.process.Child.init(argv, ally);
    try child.spawn();
    _ = try child.wait();
}


test "install" {
    const ally = std.heap.page_allocator;
    var z = ZVM.init();
    
    if (!util.file_exists("index.json")){ 
        const mirror_uri = try std.Uri.parse("https://zig.linus.dev/zig/index.json");
        try z.update_index_json(mirror_uri, ally);
    }


    const opt: JsonOptions = .{
        .version = "0.13.0",
        .arch = "x86_64",
        .os = "linux",
    };
    const tarball = "zig-linux-x86_64-0.13.0.tar.xz";
    if (!util.file_exists(tarball) {
        try z.zvm_download_tarball(ally, opt);
    }
    
    try z.zvm_install_tarball(tarball, ally);
}
