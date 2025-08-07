const std = @import("std"); 
const printf = std.debug.print;

pub fn main() !void {
    const url = "https://gavinmallott.com/index.html";


    const uri = try std.Uri.parse(url);

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
    


    var buffer: [4096]u8 = undefined;
    while (true) {
        const n = try req.read(&buffer);
        if (n == 0) break;
    }
    printf("Read file: \n{s}\n", .{buffer[0..]});

    //printf("Downloaded to '{s}'\n", .{output_path});
}
