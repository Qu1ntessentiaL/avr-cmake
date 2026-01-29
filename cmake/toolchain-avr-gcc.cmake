# cmake/toolchain-avr-gcc.cmake
# Modern, minimal AVR toolchain file — только инструменты и sysroot поиск.

# System
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)

# Compilers (просто указываем; реальные бинарники ожидаются в PATH или CMAKE_FIND_ROOT_PATH)
set(CMAKE_C_COMPILER   avr-gcc)
set(CMAKE_CXX_COMPILER avr-g++)
set(CMAKE_ASM_COMPILER avr-gcc)

# Binary utils (кэшируем как INTERNAL, чтобы быть доступны в проекте)
set(CMAKE_OBJCOPY avr-objcopy CACHE INTERNAL "")
set(CMAKE_SIZE    avr-size    CACHE INTERNAL "")
set(CMAKE_OBJDUMP avr-objdump CACHE INTERNAL "")
set(CMAKE_AVRDUDE avrdude     CACHE INTERNAL "")

# Sysroot / AVR_FIND_ROOT_PATH detection (fallbacks, как в старом скрипте)
if (DEFINED ENV{AVR_FIND_ROOT_PATH})
    set(CMAKE_FIND_ROOT_PATH $ENV{AVR_FIND_ROOT_PATH})
elseif (EXISTS "C:/avr8-gnu-toolchain-win32_x86_64/avr")
    set(CMAKE_FIND_ROOT_PATH "C:/avr8-gnu-toolchain-win32_x86_64/avr")
elseif (EXISTS "/usr/lib/avr")
    set(CMAKE_FIND_ROOT_PATH "/usr/lib/avr")
elseif (EXISTS "/usr/local/CrossPack-AVR")
    set(CMAKE_FIND_ROOT_PATH "/usr/local/CrossPack-AVR")
elseif (EXISTS "/opt/avr-gcc/avr8-gnu-toolchain-linux_x86_64/avr")
    set(CMAKE_FIND_ROOT_PATH "/opt/avr-gcc/avr8-gnu-toolchain-linux_x86_64/avr")
else ()
    message(STATUS "AVR_FIND_ROOT_PATH not set — you may set environment AVR_FIND_ROOT_PATH if needed.")
endif()

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# System include / lib paths (useful for avr libc headers)
if (DEFINED CMAKE_FIND_ROOT_PATH)
    set(CMAKE_SYSTEM_INCLUDE_PATH "${CMAKE_FIND_ROOT_PATH}/include" CACHE INTERNAL "")
    set(CMAKE_SYSTEM_LIBRARY_PATH "${CMAKE_FIND_ROOT_PATH}/lib" CACHE INTERNAL "")
endif()

# Make try-compile produce STATIC libs (avoid trying to compile host-executables)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
