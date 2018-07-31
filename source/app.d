import core.stdc.stdio : printf;
// import derelict.sdl2.sdl;

import core.stdc.stdlib;
import core.stdc.string: memcpy;

import erupted.vulkan_lib_loader;
import erupted;

import deneb.unique: Unique, SomeInterface;

import deneb.allocator: Mallocator;

import std.traits;

struct A {
  this(float value) {
    this.floatValue = value;
  }

  ~this() {
    printf("Destruct %f\n", this.floatValue);
  }

  float floatValue;
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
  foreach (m; __traits(allMembers, Mallocator)) {
    import core.stdc.stdio;
    const(char)* str = m;
    printf("member: %s\n", str);
  }
  printf("__traits end\n");

  // auto ua = Unique!A(42.0f);

  // SDL test

  // ct.tst();

}

// void vulkanTest() {
//    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
//     printf("could not initialize sdl2: %s\n", SDL_GetError());
//     return;
//   }

//   auto window = SDL_CreateWindow(
//     "hello_sdl2",
    // SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
//     1280, 720,
//     SDL_WINDOW_SHOWN
//   );

//   if (window == null) {
//     printf("could not create window: %s\n", SDL_GetError());
//     return;
//   }

//   auto screenSurface = SDL_GetWindowSurface(window);
//   // SDL_FillRect(screenSurface, NULL, SDL_MapRGB(screenSurface.format, 0xFF, 0xFF, 0xFF));
//   SDL_UpdateWindowSurface(window);
//   SDL_Delay(100);

// 	// load global level functions
// 	loadGlobalLevelFunctions();

//   VkApplicationInfo appInfo = {
// 		pApplicationName: "Vulkan Test",
// 		apiVersion: VK_MAKE_VERSION(1, 0, 2),
// 	};

//   VkInstanceCreateInfo instInfo = {
// 		pApplicationInfo: &appInfo,
// 	};

//   VkInstance instance;
// 	auto res = vkCreateInstance(&instInfo, null, &instance);

//   if(res == VkResult.VK_SUCCESS) {
//     printf("Vulkan Success \n");
//   } else {
//     printf("Vulkan Failure \n");
//   }

//   loadInstanceLevelFunctions(instance);

//   uint numPhysDevices = 4;
//   VkPhysicalDevice[4] physDevices;
// 	res = vkEnumeratePhysicalDevices(instance, &numPhysDevices, physDevices.ptr);

//   if(res == VkResult.VK_SUCCESS) {
//     printf("Vulkan Success \n");
//   } else {
//     printf("Vulkan Failure \n");
//   }

//   printf("numPhysDevices: %i\n", numPhysDevices);

//   for (auto i = 0; i< numPhysDevices; i++) {
//     VkPhysicalDeviceProperties properties;
// 		vkGetPhysicalDeviceProperties(physDevices[i], &properties);
//     printf("Physical device %i: %s \n", i, properties.deviceName.ptr);
//   }

//   SDL_Delay(100);

//   SDL_DestroyWindow(window);
//   SDL_Quit();
// }

extern(C) void main()
{
  run();
  // vulkanTest();
}
