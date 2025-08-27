const Component = @import("Component.zig");
const System = @This();

ptr: *anyopaque,
component_types: []const type,
runFn: *const fn ([]*Component) void,

pub fn init(ptr: anytype, comptime component_types: []const type) System {
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

    inline for (component_types) |component_type| {
        if (!@hasDecl(component_type, "deinit")) @compileError(@typeName(T) ++ " must implement a deinit method to be a Component");
    }

    return .{
        .ptr = ptr,
        .component_types = component_types,
        .runFn = gen.run,
    };
}

pub fn run(self: *System, components: []*Component) void {
    return try self.runFn(components);
}
