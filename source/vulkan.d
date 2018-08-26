module deneb.vulkan;

import core.stdc.stdio : printf;

import derelict.sdl2.sdl;
import erupted.vulkan_lib_loader;
import erupted;

void vkAssert(VkResult result) {
  if (result != VkResult.VK_SUCCESS) {
    printf("Vulkan Failure \n");
  }
}

void runVulkanTest() {
   if (SDL_Init(SDL_INIT_VIDEO) < 0) {
    printf("could not initialize sdl2: %s\n", SDL_GetError());
    return;
  }

  auto window = SDL_CreateWindow(
    "hello_sdl2",
    SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
    1280, 720,
    SDL_WINDOW_SHOWN
  );

  if (window == null) {
    printf("could not create window: %s\n", SDL_GetError());
    return;
  }

  auto screenSurface = SDL_GetWindowSurface(window);
  // SDL_FillRect(screenSurface, NULL, SDL_MapRGB(screenSurface.format, 0xFF, 0xFF, 0xFF));
  SDL_UpdateWindowSurface(window);
  SDL_Delay(100);

	// load global level functions
	loadGlobalLevelFunctions();

  VkApplicationInfo appInfo = {
		pApplicationName: "Vulkan Test",
		apiVersion: VK_MAKE_VERSION(1, 0, 2),
	};

  VkInstanceCreateInfo instInfo = {
		pApplicationInfo: &appInfo,
	};

  VkInstance instance;
	vkAssert(vkCreateInstance(&instInfo, null, &instance));

  loadInstanceLevelFunctions(instance);

  uint numPhysDevices = 4;
  VkPhysicalDevice[4] physDevices;
	vkAssert(vkEnumeratePhysicalDevices(instance, &numPhysDevices, physDevices.ptr));

  printf("numPhysDevices: %i\n", numPhysDevices);

  for (auto i = 0; i< numPhysDevices; i++) {
    VkPhysicalDeviceProperties properties;
		vkGetPhysicalDeviceProperties(physDevices[i], &properties);
    printf("Physical device %i: %s \n", i, properties.deviceName.ptr);
  }

  SDL_Delay(100);

  SDL_DestroyWindow(window);
  SDL_Quit();
}
