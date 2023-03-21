const std = @import("std");
const c = @import("bindings/common.zig");

const SomeThing = struct {
    event: ?*c.event,
    content: []const u8,
    counter: *u32,
};
pub fn say_something(fd: c_int, events: c_short, thing: *SomeThing) callconv(.C) void {
    _ = fd;
    _ = events;
    const max_called = 5;
    std.debug.print("Say: \"{s}\"\tcounter: {d}\n", .{ thing.content, thing.counter.* });
    thing.counter.* += 1;
    if (thing.counter.* >= max_called and thing.event != null) {
        _ = c.event_del(thing.event);
    }
}

// You could do that? Return a type and apply it
fn event_callback(comptime T: type) type {
    return *const fn (c_int, c_short, *T) callconv(.C) void;
}

// Marking your functions with the C calling convention is crucial when you’re calling Zig from C.
/// A type safe `event_new`
pub fn event_new(base: *c.event_base, fd: c_int, events: c_short, comptime T: type, callback: event_callback(T), callback_arg: *T) ?*c.event {
    var cb = @ptrCast(c.event_callback_fn, callback);
    var arg = @ptrCast(*anyopaque, callback_arg);
    return c.event_new(base, fd, events, cb, arg);
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

    var base = c.event_base_new().?;
    var tv = c.timeval{
        .tv_sec = 1,
        .tv_usec = 0,
    };
    // If the EV_PERSIST flag is set on an event, however, the event is
    // persistent. This means that event remains pending even when its callback
    // is activated. If you want to make it non-pending from within its
    // callback, you can call event_del() on it.
    var ev = event_new(base, -1, c.EV_PERSIST, SomeThing, &say_something, thing);
    // you don't actually needs `event_self_cbarg()`
    thing.event = ev;
    _ = c.event_add(ev, &tv);
    _ = c.event_base_dispatch(base);
}
