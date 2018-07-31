
module deneb.unique;

import core.stdc.stdio : printf;
import core.stdc.stdlib: malloc, free;

@nogc

struct Unique(T) {
  import deneb.proxy: Proxy;
  mixin Proxy!_ptr;

  this(Args...)(auto ref Args args) {
    this._ptr = cast(T*)malloc(T.sizeof);
    {
      import std.conv: emplace;
      printf("assign before \n");
      emplace(this._ptr, args);
    // *this._ptr = T(45.0);
      printf("assign after \n");
    }
  }

  @disable this(this);

  ~this() {
    if (this._ptr != null) {
      destroy(*this._ptr);
      free(this._ptr);
      this._ptr = null;
    }
  }

  T* _ptr = null;
}


extern(C++) {

  class ClassTest {
    @nogc

    this(int number)
    {
      // printf("ClassTest::constructor\n");
    }

    ~this() {
      printf("ClassTest::destructor\n");
    }

    void tst()
    {
      printf("ClassTest::tst\n");
    }

    private:
    // Used by construction hack
    this() pure {}
  }
}


struct AllocatorBase {

}

interface SomeInterface {
  void* allocate(int number);
}