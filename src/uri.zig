const std = @import("std"); 
const builtin = @import("builtin");
const printf = std.debug.print;

pub const JsonOptions = struct {
    version: []const u8 = "0.14.1",
    os: []const u8 = @tagName(builtin.target.os.tag),
    arch: []const u8 = @tagName(builtin.target.cpu.arch),
};

pub fn select_zig_url_from_json(
    filename: []const u8,
    allocator: std.mem.Allocator,
    opt: JsonOptions,
) ![]const u8 {
    // Open Json File
    const jsonfile = try std.fs.cwd().openFile(filename, .{});
    defer jsonfile.close();

    // Read Json File w/ Allocator
    const filedata = try jsonfile.readToEndAlloc(allocator, std.math.maxInt(u32));
    defer allocator.free(filedata);

    // Parse Json File
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, filedata, .{});
    defer parsed.deinit();

    // Root of Parsed Json
    var root = parsed.value;

    // Create arch_os string based on opt
    var tmp: [128]u8 = undefined;
    const arch_os = try std.fmt.bufPrint(tmp[0..], "{s}-{s}", .{opt.arch, opt.os});

    // Walk Json
    if (root.object.contains(opt.version)) {
        const version = root.object.get(opt.version).?;
        if (version.object.contains(arch_os)) {
            const arch_os_v = version.object.get(arch_os).?;
            const tarball = arch_os_v.object.get("tarball").?;
            const tarball_str = tarball.string;

            return try allocator.dupe(u8, tarball_str);
        } else {
            printf ("Zig download for {s} not found.\n", .{arch_os});
            return "";
        }
    } else {
        printf ("Zig version {s} not found.\n", .{opt.version});
        return "";
    }
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
    
    const m = try req.readAll(buffer);
    return m;
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
        try file.writeAll(buffer[0..m]);
        n += m;
    }
    return n;
}

// test "uri and json" {
//     const url = "https://zig.linus.dev/zig/index.json";
//     const uri = try std.Uri.parse(url);
//     //var buffer: [2048]u8 = undefined;
//     const ally = std.heap.page_allocator;
//     const opt = JsonOptions{
//         .version = "master",
//         .os = "linux",
//         .arch = "x86_64",
//    };

//    var big_buf = try ally.alloc(u8, std.math.maxInt(u32));
//    defer ally.free(big_buf);
//    
//    const buflen = try read_uri_into_buffer(uri, big_buf[0..]);
//    printf("Big Buffer contents: \n{s}\n\n", .{big_buf[0..buflen]});
//
//
//    //_ = try read_uri_into_buffer(uri, buffer[0..]);
//    //_ = try read_uri_into_file(uri, "index.json", ally);
//    const tarball = try select_zig_url_from_json("index.json", ally, opt);
//    defer ally.free(tarball);
//    printf("Selected: {s} for install.\n", .{tarball});
//
//    const tarball2 = try select_zig_url_from_json("index.json", ally, .{
//        .version = "0.13.0",
//        .os = "macos",
//        .arch = "aarch64",
//    });
//    defer ally.free(tarball2);
//    printf("Selected: {s} for install.\n", .{tarball2});
//
//    const tarball3 = try select_zig_url_from_json("index.json", ally, .{});
//    defer ally.free(tarball3);
//    printf("Selected: {s} for install.\n", .{tarball3});
//}
