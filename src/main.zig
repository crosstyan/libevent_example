const std = @import("std");
const c = @import("bindings/common.zig");

const SomeThing = struct {
    content: []const u8,
    counter: *u32,
};
pub fn say_something(fd: c_int, events: c_short, arg: ?*anyopaque) callconv(.C) void {
    _ = fd;
    _ = events;
    var cast = @alignCast(@alignOf(*SomeThing), arg.?);
    var thing = @ptrCast(*SomeThing, cast);
    std.debug.print("Say: \"{s}\"\tcounter: {d}\n", .{ thing.content, thing.counter.* });
    thing.counter.* += 1;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var p = try allocator.create(u32);
    p.* = 0;
    defer allocator.destroy(p);
    var thing = try allocator.create(SomeThing);
    defer allocator.destroy(thing);
    const content = "Hello, world!";
    thing.* = SomeThing{
        .content = content[0..],
        .counter = p,
    };

    var base = c.event_base_new();
    var tv = c.timeval{
        .tv_sec = 1,
        .tv_usec = 0,
    };
    // If the EV_PERSIST flag is set on an event, however, the event is
    // persistent. This means that event remains pending even when its callback
    // is activated. If you want to make it non-pending from within its
    // callback, you can call event_del() on it.
    var ev = c.event_new(base, -1, c.EV_PERSIST, &say_something, @ptrCast(*anyopaque, thing));
    _ = c.event_add(ev, &tv);
    _ = c.event_base_dispatch(base);
}
