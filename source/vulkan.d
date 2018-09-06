module deneb.vulkan;

import core.stdc.stdio : printf;

import core.stdc.stdlib: exit;

import derelict.sdl2.sdl;
import erupted.vulkan_lib_loader;
import erupted;

alias ConstCStr = const(char)*;
alias uint32 = uint;
alias int32 = int;

private void vkAssert(VkResult result) {
  if (result != VkResult.VK_SUCCESS) {
    printf("Vulkan Failure \n");
    exit(-1);
  }
}

private void vkAssert(SDL_bool result) {
  if (!result) {
    printf("Vulkan Failure \n");
    exit(-1);
  }
}

/**
 *  vulkan test function
 */
void runVulkanTest() {
  printf("\nVULKAN TEST\n==============\n");

  if (SDL_Init(SDL_INIT_VIDEO) < 0) {
    printf("could not initialize sdl2: %s\n", SDL_GetError());
    return;
  }

  if (SDL_Vulkan_LoadLibrary(null) < 0) {
    printf("could not initialize sdl2_vulkan: %s\n", SDL_GetError());
    return;
  }

  auto window = SDL_CreateWindow(
    "hello_sdl2",
    SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
    1280, 720,
    SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE | SDL_WINDOW_VULKAN
  );

  if (window == null) {
    printf("could not create window: %s\n", SDL_GetError());
    return;
  }

  uint requiredExtensionsCount = 16;
  ConstCStr[16] requiredExtensions;
  if (!SDL_Vulkan_GetInstanceExtensions(window, &requiredExtensionsCount, &requiredExtensions[0])) {
    printf("error: SDL_Vulkan_GetInstanceExtensions\n");
    printf(" %s \n", SDL_GetError());
  } else if (requiredExtensionsCount >= 16) {
    printf("error: too many required extensions\n");
    exit(-1);
  } else {
    requiredExtensions[requiredExtensionsCount++] = VK_EXT_DEBUG_REPORT_EXTENSION_NAME;
    printf("requiredExtensionsCount: %i \n", requiredExtensionsCount);
    for (auto i = 0 ; i < requiredExtensionsCount; i++) {
      printf("- %s\n", requiredExtensions[i]);
    }
  }


  SDL_Delay(100);

	// load global level vulkan functions
	loadGlobalLevelFunctions();

  VkApplicationInfo appInfo = {
		pApplicationName: "Vulkan Test",
		apiVersion: VK_MAKE_VERSION(1, 0, 2),
	};

  ConstCStr[1] validationLayers = ["VK_LAYER_LUNARG_standard_validation"];
  const auto validationLayersCount = 1;

  VkInstanceCreateInfo instInfo = {
		pApplicationInfo: &appInfo,

    enabledExtensionCount: requiredExtensionsCount,
    ppEnabledExtensionNames: &requiredExtensions[0],

    enabledLayerCount: validationLayersCount,
    ppEnabledLayerNames: &validationLayers[0]
	};

  VkInstance instance;
	vkAssert(vkCreateInstance(&instInfo, null, &instance));

  // load instance level functions
  loadInstanceLevelFunctions(instance);

  // register debug message callback
  VkDebugReportCallbackCreateInfoEXT callbackCreateInfo = {
    flags:  VK_DEBUG_REPORT_INFORMATION_BIT_EXT |
            VK_DEBUG_REPORT_DEBUG_BIT_EXT |
            VK_DEBUG_REPORT_ERROR_BIT_EXT |
            VK_DEBUG_REPORT_WARNING_BIT_EXT |
            VK_DEBUG_REPORT_PERFORMANCE_WARNING_BIT_EXT,
    pfnCallback: &MyDebugReportCallback,
  };

  VkDebugReportCallbackEXT callback;
  vkAssert(vkCreateDebugReportCallbackEXT(instance, &callbackCreateInfo, null, &callback));

  verbosePrint(instance);

  selectDevice(instance);

  // createSurface(instance, window);

  SDL_Delay(100);

  SDL_DestroyWindow(window);
  SDL_Quit();
}

extern(Windows) nothrow @nogc VkBool32 MyDebugReportCallback  (
    VkDebugReportFlagsEXT       flags,
    VkDebugReportObjectTypeEXT  objectType,
    uint64_t                    object,
    size_t                      location,
    int32_t                     messageCode,
    const char*                 pLayerPrefix,
    const char*                 pMessage,
    void*                       pUserData)
{
    printf("VK: %s \n\n", pMessage);
    return VK_FALSE;
}

private void createSurface(ref VkInstance instance, SDL_Window* window) {
  VkSurfaceKHR surface;
  vkAssert(SDL_Vulkan_CreateSurface(window, instance, &surface));
}

private struct DeviceContext {
  VkPhysicalDevice physicalDevice;
  VkDevice logicalDevice;
  VkPhysicalDeviceProperties physicalDeviceProperties;
  uint32 graphicsQueueFamilyIndex;
  VkQueue graphicsQueue;
}

private DeviceContext selectDevice(ref VkInstance instance) {
  // load up to 4 physical devices
  uint32 numPhysicalDevices = 4;
  VkPhysicalDevice[4] physicalDevices;
	vkAssert(vkEnumeratePhysicalDevices(instance, &numPhysicalDevices, physicalDevices.ptr));

  DeviceContext discreteSelection;
  DeviceContext integratedSelection;
  bool discreteGPUFound;
  bool integratedGPUFound;

  for (auto i = 0; i< numPhysicalDevices; i++) {
    VkPhysicalDeviceProperties properties;
		vkGetPhysicalDeviceProperties(physicalDevices[i], &properties);

    const isDiscrete = properties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU;
    const isIntegrated = properties.deviceType == VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU;

    uint32 numQueueFamilies = 8;
    VkQueueFamilyProperties[8] queueFamilyProperties;
    vkGetPhysicalDeviceQueueFamilyProperties(
      physicalDevices[i],
      &numQueueFamilies,
      queueFamilyProperties.ptr
    );

    int32 selectedQueueFamilyIndex = -1;

    for (auto j = 0; j < numQueueFamilies; j++) {
      const goodQueue =
        (queueFamilyProperties[j].queueFlags & VK_QUEUE_GRAPHICS_BIT) &&
        (queueFamilyProperties[j].queueFlags & VK_QUEUE_TRANSFER_BIT) &&
        queueFamilyProperties[j].queueCount > 0;

      if (goodQueue) {
        selectedQueueFamilyIndex = j;
        break;
      }
    }

    if (!discreteGPUFound && isDiscrete && selectedQueueFamilyIndex != -1) {
      discreteSelection.physicalDevice = physicalDevices[i];
      discreteSelection.physicalDeviceProperties = properties;
      discreteSelection.graphicsQueueFamilyIndex = selectedQueueFamilyIndex;
      discreteGPUFound = true;
    }

    if (!integratedGPUFound && isIntegrated && selectedQueueFamilyIndex != -1) {
      integratedSelection.physicalDevice = physicalDevices[i];
      integratedSelection.physicalDeviceProperties = properties;
      integratedSelection.graphicsQueueFamilyIndex = selectedQueueFamilyIndex;
      integratedGPUFound = true;
    }
  }

  // early out if we didn't find a physical device with enough features
  if (!discreteGPUFound && !integratedGPUFound) {
    printf("ERROR: no supported GPU found \n");
    exit(-1);
    assert(false);
  }

  auto context = discreteGPUFound ? &discreteSelection : &integratedSelection;

    printf(
      "selectedQueueFamilyIndex: %i\n",
      context.graphicsQueueFamilyIndex,
    );

  const float[1] priorities = [ 1.0f ];
  const VkDeviceQueueCreateInfo queueCreateInfo = {
    pNext: null,
    flags: 0,
    queueFamilyIndex: context.graphicsQueueFamilyIndex,
    queueCount: 1,
    pQueuePriorities: &priorities[0]
  };

  const ConstCStr[1] enabledExtensions = [ VK_KHR_SWAPCHAIN_EXTENSION_NAME ];
  VkDeviceCreateInfo deviceCreateInfo;
    deviceCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    deviceCreateInfo.pNext = null;
    deviceCreateInfo.flags = 0;
    deviceCreateInfo.queueCreateInfoCount = 1;
    deviceCreateInfo.pQueueCreateInfos = &queueCreateInfo;
    deviceCreateInfo.enabledExtensionCount = 1;
    deviceCreateInfo.ppEnabledExtensionNames = &enabledExtensions[0];
    deviceCreateInfo.pEnabledFeatures = null;

  vkAssert(vkCreateDevice(
    context.physicalDevice,
    &deviceCreateInfo,
    null,
    &context.logicalDevice
  ));

  vkDebugReportMessageEXT(
    instance,
    VK_DEBUG_REPORT_INFORMATION_BIT_EXT,
    VK_DEBUG_REPORT_OBJECT_TYPE_UNKNOWN_EXT,
    0,
    0,
    0,
    "blubb",
    "hello vulkan message"
  );

  loadDeviceLevelFunctions(instance);

  vkGetDeviceQueue(
    context.logicalDevice,
    context.graphicsQueueFamilyIndex,
    0,
    &context.graphicsQueue
  );

  return *context;
}

private void verbosePrint(ref VkInstance instance) {
  // load up to 4 physical devices
  uint32 numPhysicalDevices = 4;
  VkPhysicalDevice[4] physicalDevices;
	vkAssert(vkEnumeratePhysicalDevices(instance, &numPhysicalDevices, physicalDevices.ptr));

  for (auto i = 0; i< numPhysicalDevices; i++) {
    VkPhysicalDeviceProperties properties;
		vkGetPhysicalDeviceProperties(physicalDevices[i], &properties);
    verbosePrint(properties);

    uint32 numQueueFamilies = 8;
    VkQueueFamilyProperties[8] queueFamilyProperties;
    vkGetPhysicalDeviceQueueFamilyProperties(
      physicalDevices[i],
      &numQueueFamilies,
      queueFamilyProperties.ptr
    );

    for (auto j = 0; j < numQueueFamilies; j++) {
      verbosePrint(j, queueFamilyProperties[j]);
    }
  }
}

private void verbosePrint(in VkPhysicalDeviceProperties props) {
  printf("name: %s \n", props.deviceName.ptr);
  printf("  apiVersion: %i\n", props.apiVersion);
  printf("  driverVersion: %i\n", props.driverVersion);
  printf("  vendorID: %i\n", props.vendorID);
  printf("  deviceID: %i\n", props.deviceID);

  ConstCStr[5] deviceTypeStrings = [
    "other", "integrated GPU", "discrete GPU", "virtual GPU", "CPU"
  ];

  if (props.deviceType < 5) {
    printf("  deviceType: %s\n", deviceTypeStrings[props.deviceType]);
  }

  // TODO limits
}

private void verbosePrint(uint32 index, in VkQueueFamilyProperties props) {
  printf("  queue index: %i \n", index);
  printf("    count: %i \n", props.queueCount);

  printf("    queueFlags: \n");
  if ( props.queueFlags & VK_QUEUE_GRAPHICS_BIT) {
    printf("      graphics\n");
  }
  if ( props.queueFlags & VK_QUEUE_COMPUTE_BIT) {
    printf("      compute\n");
  }
  if ( props.queueFlags & VK_QUEUE_TRANSFER_BIT) {
    printf("      transfer\n");
  }
  if ( props.queueFlags & VK_QUEUE_SPARSE_BINDING_BIT) {
    printf("      sparse binding\n");
  }
}