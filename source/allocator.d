module deneb.allocator;
import core.stdc.stdlib: free;

@nogc

alias u32 = uint;
alias u64 = ulong;

struct Mallocator {
  void* allocate(u32 byteSize) {
    import core.stdc.stdlib: malloc;
    return malloc(byteSize);
  }

  void free(void* ptr) {
    import core.stdc.stdlib: free;
    free(ptr);
  }

  static immutable IAllocatorFunctions __IAllocatorFunctions = {
    allocate: function void*(void* _self, u32 byteSize) {
      auto self = cast(Mallocator*) _self;
      return self.allocate(byteSize);
    },
    free: function void(void* _self, void* ptr) {
      auto self = cast(Mallocator*) _self;
      return self.free(ptr);
    }
  };

  IAllocator getIAllocator() {
    IAllocator result = {
      self: &this,
      vtable: &Mallocator.__IAllocatorFunctions
    };
    return result;
  }
}

struct IAllocator {
  private void* self;
  private immutable IAllocatorFunctions* vtable;

  void* allocate(u32 byteSize) {
    return this.vtable.allocate(this.self, byteSize);
  }

  void free(void* ptr) {
    return this.vtable.free(this.self, ptr);
  }
}

struct IAllocatorFunctions {
  void* function(void* that, u32 byteSize) allocate;
  void function(void* that, void* ptr) free;
}