const std = @import("std");
const c = @cImport({
    @cInclude("curl/curl.h");
});

pub fn readZig() ![]const u8 {
    if (c.curl_global_init(c.CURL_GLOBAL_DEFAULT) != 0) return "Failed to initialize libcurl\n"; 
    defer c.curl_global_cleanup();

    const curl = c.curl_easy_init();
    if (curl == null) return "Failed to initialize libcurl\n";
    defer c.curl_easy_cleanup(curl);
}
pub const zig_pub_key = "RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U";


