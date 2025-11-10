const std = @import("std");
const Entity = @import("Entity.zig");
const Component = @import("Component.zig");
const Context = @This();

allocator: std.mem.Allocator,
entities: std.ArrayList(Entity),
components: std.AutoArrayHashMap([]const type, std.ArrayList(Entity)),

pub fn init(allocator: std.mem.Allocator) Context {
    return .{
        .allocator = allocator,
        .entities = std.ArrayList(Entity).empty,
    };
}

pub fn deinit(self: *Context) void {
    for (self.entities) |entity| {
        entity.deinit();
    }
    try self.entities.deinit(self.allocator);
}

pub fn createEntity(self: *Context, allocator: std.mem.Allocator) std.mem.Allocator.Error!*Entity {
    const vtable = .{
        .new_component = self.newComponent,
        .removed_component = self.removedComponent,
    };
    const entity = Entity.init(
        self.entities.items.len,
        self,
        allocator,
        vtable,
    );
    try self.entities.append(self.allocator, entity);
    return self.entities.items[self.entities.items.len - 1];
}

fn newComponent(self: *Context, id: usize, component: *Component) void {}

fn removedComponent(self: *Context, id: usize, component: *Component) void {}

fn getComponentListsWithType(comptime T: type) ?[]type {}

pub fn createSystem(self: *Context, comptime components: []const type) void {}
