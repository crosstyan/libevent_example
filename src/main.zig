const std = @import("std");
const c = @import("bindings/common.zig");

const SomeThing = struct {
    event: ?*c.event,
    content: []const u8,
    counter: *u32,
};
pub fn say_something(fd: c_int, events: c_short, arg: ?*anyopaque) callconv(.C) void {
    _ = fd;
    _ = events;
    // https://www.reddit.com/r/Zig/comments/1119m6g/what_does_aligncast_do/
    var cast = @alignCast(@alignOf(*SomeThing), arg.?);
    var thing = @ptrCast(*SomeThing, cast);
    std.debug.print("Say: \"{s}\"\tcounter: {d}\n", .{ thing.content, thing.counter.* });
    thing.counter.* += 1;
    if(thing.counter.* > 5 and thing.event != null){
        _ = c.event_del(thing.event);
    }
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
        .event = null,
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
    // you don't actually needs `event_self_cbarg()`
    thing.event = ev;
    _ = c.event_add(ev, &tv);
    _ = c.event_base_dispatch(base);
}
