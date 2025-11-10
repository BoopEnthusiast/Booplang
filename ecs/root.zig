pub const Context = @import("Context.zig");
pub const Entity = @import("Entity.zig");
pub const Component = @import("Component.zig");
pub const System = @import("System.zig");

const std = @import("std");

test "Make context" {
    var buffer: [1000]u8 = undefined;
    var f_b_allocator = std.heap.FixedBufferAllocator.init(&buffer);
    var context = Context.init(f_b_allocator.allocator());
    defer context.deinit();

    var buffer2: [100]u8 = undefined;
    var f_b_allocator2 = std.heap.FixedBufferAllocator.init(&buffer2);
    const entity = context.createEntity(f_b_allocator2.allocator());
    _ = entity;
}
