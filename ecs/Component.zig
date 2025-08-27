const Component = @This();

ptr: *anyopaque,
deinitFn: *const fn (ptr: *anyopaque) void,

pub fn init(ptr: anytype) Component {
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

pub fn deinit(self: *Component) void {
    self.deinitFn(self.ptr);
}
