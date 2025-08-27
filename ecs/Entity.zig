const std = @import("std");
const Component = @import("Component.zig");
const Entity = @This();

id: usize,
allocator: std.mem.Allocator,
components: std.SegmentedList(Component),
vtable: *const VTable,

const VTable = struct {
    new_component: *const fn (id: usize, component: *Component) void,
    removed_component: *const fn (id: usize, component: *Component) void,
};

fn init(id: usize, allocator: std.mem.Allocator, vtable: VTable) Entity {
    return Entity{
        .id = id,
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
