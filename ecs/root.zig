const std = @import("std");

pub const Context = struct {
    allocator: std.mem.Allocator,
    entities: std.ArrayList(Entity),
    components: std.AutoArrayHashMap([]const type, std.ArrayList(Entity)),

    pub fn init(allocator: std.mem.Allocator) Context {
        return Context{
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
            allocator,
            vtable,
        );
        try self.entities.append(self.allocator, entity);
        return self.entities.items[self.entities.items.len - 1];
    }

    fn newComponent(id: usize, component: *Component) void {}

    fn removedComponent(id: usize, component: *Component) void {}

    pub fn createSystem(self: *Context, comptime components: []const type) void {}
};

pub const Entity = struct {
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
};

pub const System = struct {
    ptr: *anyopaque,
    types: []const type,
    runFn: *const fn ([]*Component) void,

    fn init(ptr: anytype, components: []const Component) System {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        if (ptr_info != .pointer) @compileError("ptr must be a pointer");
        if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
        if (@typeInfo(ptr_info.pointer.child) != .Struct) @compileError("ptr must point to a struct");

        const gen = struct {
            pub fn run(pointer: *anyopaque, cmpnts: []*Component) void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.deinit(self, cmpnts);
            }
        };

        // TODO: Implment system for taking the components parameter and getting the list of their actual types and then passing that to .types below

        return .{
            .ptr = ptr,
            .types = undefined,
            .runFn = gen.run,
        };
    }

    pub fn run(self: *System, components: []*Component) void {
        return try self.runFn(components);
    }
};

pub const Component = struct {
    ptr: *anyopaque,
    deinitFn: *const fn (ptr: *anyopaque) void,

    fn init(ptr: anytype) Component {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        if (ptr_info != .pointer) @compileError("ptr must be a pointer");
        if (ptr_info.pointer.size != .one) @compileError("ptr must be a single item pointer");
        if (@typeInfo(ptr_info.pointer.child) != .Struct) @compileError("ptr must point to a struct");

        const gen = struct {
            pub fn deinit(pointer: *anyopaque) void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.deinit(self);
            }
        };

        return .{
            .ptr = ptr,
            .deinitFn = gen.deinit,
        };
    }

    fn deinit(self: *Component) void {
        self.deinitFn(self.ptr);
    }
};
