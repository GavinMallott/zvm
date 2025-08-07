const std = @import("std"); 
const builtin = @import("builtin");
const printf = std.debug.print;

pub fn main() !void {
    const url = "https://zig.linus.dev/zig/index.json";
    const uri = try std.Uri.parse(url);
    var buffer: [2048]u8 = undefined;
    const ally = std.heap.page_allocator;
    const opt = JsonOptions{
        .version = "0.14.0",
        .os = "linux",
        .arch = "x86-64",
    };

    _ = try read_uri_into_buffer(uri, buffer[0..]);
    _ = try read_uri_into_file(uri, "index.json", ally);
    _ = try select_zig_version_from_json("index.json", ally, opt);

    //printf("Downloaded to '{s}'\n", .{output_path});
}

pub const JsonOptions = struct {
    version: []const u8 = "stable",
    os: []const u8 = @tagName(builtin.target.os.tag),
    arch: []const u8 = @tagName(builtin.target.cpu.arch),
};

pub fn select_zig_version_from_json(
    filename: []const u8,
    allocator: std.mem.Allocator,
    opt: JsonOptions,
) ![]const u8 {
    const jsonfile = try std.fs.cwd().openFile(filename, .{});
    defer jsonfile.close();

    const filedata = try jsonfile.readToEndAlloc(allocator, std.math.maxInt(u32));
    defer allocator.free(filedata);

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, filedata, .{});
    defer parsed.deinit();

    var root = parsed.value;
    
    var root_it = root.object.iterator();
    while(root_it.next()) |node| {
        printf("{s}\n", .{node.key_ptr.*});
        //node.value_ptr.*.dump();
        //printf("\n", .{});
    }

    var version_name: [128]u8 = undefined;

    const version_slice = try std.fmt.bufPrint(version_name[0..], "https://ziglang.org/builds/{s}.tar.xz", .{opt.version});
    printf("Requested Version: {s}\n", .{version_slice});
    return version_slice;

}

pub fn read_uri_into_buffer(uri: std.Uri, buffer: []u8) !usize {
    var client = std.http.Client{
        .allocator = std.heap.page_allocator,
    };
    defer client.deinit();

    var server_headers_buffer: [1024]u8 = undefined; // static buffer for response headers

    var req = try client.open(.GET, uri, .{
        .server_header_buffer = &server_headers_buffer,
    });
    defer req.deinit();

    try req.send();
    try req.finish();

    try req.wait();
    
    while (true) {
        const m = try req.read(buffer);
        if (m == 0) break;
        //printf("Read file: \n{s}\n", .{buffer[0..m]});
    }
    return 0;
}

pub fn read_uri_into_file(uri: std.Uri, filename: []const u8, allocator: std.mem.Allocator) !usize {
    const buffer = try allocator.alloc(u8, std.math.maxInt(u32));
    defer allocator.free(buffer);

    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();

    var client = std.http.Client{
        .allocator = std.heap.page_allocator,
    };
    defer client.deinit();

    var server_headers_buffer: [1024]u8 = undefined; // static buffer for response headers

    var req = try client.open(.GET, uri, .{
        .server_header_buffer = &server_headers_buffer,
    });
    defer req.deinit();

    try req.send();
    try req.finish();

    try req.wait();
    
    var n: usize = 0;
    while (true) {
        const m = try req.read(buffer);
        if (m == 0) break;
        //printf("Read file: \n{s}\n", .{buffer[0..m]});
        try file.writeAll(buffer[0..m]);
        n += m;
    }
    return n;
}
