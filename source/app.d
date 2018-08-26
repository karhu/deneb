import core.stdc.stdio : printf;
import core.stdc.stdlib;
import core.stdc.string: memcpy;

import deneb.unique: Unique;

import deneb.allocator: Mallocator;

import deneb.vulkan: runVulkanTest;

import std.traits;
import std.array: join;

struct A {
  this(float value) {
    this.floatValue = value;
  }

  ~this() {
    printf("Destruct %f\n", this.floatValue);
  }

  float floatValue;
}

interface SomeInterface {
  void foo();
  int bar();

  bool yes(int number);
  bool no(string message, int number);
}

void printMemberFunctions(T)() {
  printf("__memberFunctionsBegin \n");

  foreach (name; __traits(allMembers, T)) {
    import core.stdc.stdio;
    mixin("alias member = " ~ T.stringof ~ "." ~ name ~ ";");

    alias paramNames = ParameterIdentifierTuple!member;
    alias paramTypes = ParameterTypeTuple!member;

    string[] params;



    const(char)* str = ReturnType!member.stringof ~ " " ~ name ~ "(";


    // const(char)* str = member_str;
    printf("member: %s\n", str);

    // printf(" arity %i\n", arity!member);

    // foreach (paramName ; paramNames) {
    //   const(char)* paramName_c = paramName;
    //   printf("  %s\n", paramName_c);
    // }

    import std.range: iota;

    // foreach (enum i; 0 .. arity!member) {
    //   const(char)* paramName_c = paramNames[i];
    //   const(char)* paramType_c = paramTypes[i].stringof;
    //   printf("  %s %s\n", paramType_c, paramName_c);
    // }

    // foreach (enum j; 0 .. paramNames.length) {
    //   // printf("%i", j);

    //   // static if (j < paramNames.length) {
    //     const(char)* paramName_c = paramNames[j];
    //     printf("  %s\n", paramType_c, paramName_c);
    //   // }


    //   // const(char)* paramType_c = paramTypes[j].stringof;
    //   // printf("  %s %s\n", paramType_c, paramName_c);
    // }

    static if (arity!member > 0) {
      // foreach (paramZip; zip(paramTypes, paramNames)) {

      // }
    }
  }

  printf("__memberFunctionsEnd \n");
}

void run() {
  {
    A b = A(3);
  }
  // A a;
  printf("Hello betterC\n");

  auto aa = Unique!A(32.0);

  Mallocator mallocator;

  auto someAllocator = mallocator.getIAllocator();

  void* data = someAllocator.allocate(128);
  printf("data: %p\n", data);
  someAllocator.free(data);

  SomeInterface inter = null;

  printf("__traits begin\n");
  foreach (member_str; __traits(allMembers, Mallocator)) {
    import core.stdc.stdio;
    const(char)* member_cstr = member_str;
    printf("member: %s\n", member_cstr);
  }
  printf("__traits end\n");

  printMemberFunctions!SomeInterface;

  // auto ua = Unique!A(42.0f);

  // SDL test

  // ct.tst();
}

extern(C) void main()
{
  run();
  runVulkanTest();
}
