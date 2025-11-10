const std = @import("std");
const Component = @import("Component.zig");
const Context = @import("Context.zig");
const Entity = @This();

id: usize,
context: Context,
allocator: std.mem.Allocator,
components: std.SegmentedList(Component, 0),
vtable: *const VTable,

const VTable = struct {
    new_component: *const fn (self: *Context, id: usize, component: *Component) void,
    removed_component: *const fn (self: *Context, id: usize, component: *Component) void,
};

fn init(id: usize, context: *Context, allocator: std.mem.Allocator, vtable: VTable) Entity {
    return Entity{
        .id = id,
        .context = context,
        .allocator = allocator,
        .components = std.SegmentedList(Component).empty,
        .vtable = vtable,
    };
}

fn deinit(self: *Entity) void {
    for (self.components) |component| {
        component.deinit();
    }
    self.components.deinit();
}

pub fn addComponent(self: *Entity, component: Component) std.mem.Allocator.Error!*Component {
    try self.components.append(self.allocator, component);

    return self.components.items[self.components.items.len - 1];
}
