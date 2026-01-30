# cmake/toolchain-avr-gcc.cmake
# Modern, minimal AVR toolchain file — только инструменты и sysroot поиск.

# System
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)

if (WIN32)
    set(EXECUTABLE_SUFFIX ".exe")
else ()
    set(EXECUTABLE_SUFFIX "")
endif ()

# Определяем корневой путь для тулчейна
# 1. Проверяем явную переменную AVR_TOOLCHAIN_PATH
# 2. Проверяем старый AVR_FIND_ROOT_PATH
# 3. Используем стандартные пути
if (DEFINED AVR_TOOLCHAIN_PATH)
    set(AVR_ROOT_PATH "${AVR_TOOLCHAIN_PATH}")
elseif (DEFINED ENV{AVR_FIND_ROOT_PATH})
    set(AVR_ROOT_PATH "$ENV{AVR_FIND_ROOT_PATH}")
elseif (EXISTS "C:/avr8-gnu-toolchain-win32_x86_64")
    set(AVR_ROOT_PATH "C:/avr8-gnu-toolchain-win32_x86_64")
elseif (EXISTS "/usr/lib/avr")
    set(AVR_ROOT_PATH "/usr/lib/avr")
elseif (EXISTS "/usr/local/CrossPack-AVR")
    set(AVR_ROOT_PATH "/usr/local/CrossPack-AVR")
elseif (EXISTS "/opt/avr-gcc/avr8-gnu-toolchain-linux_x86_64_v5.4.0")
    set(AVR_ROOT_PATH "/opt/avr-gcc/avr8-gnu-toolchain-linux_x86_64_v5.4.0")
else ()
    message(STATUS "AVR toolchain root not found")
    set(AVR_ROOT_PATH "")
endif()

# Вариант 1: Используем полные пути к компиляторам (рекомендуется)
if (AVR_ROOT_PATH)
    # Путь к bin директории
    set(AVR_BIN_PATH "${AVR_ROOT_PATH}/bin")

    # Компиляторы с полными путями
    set(CMAKE_C_COMPILER   "${AVR_BIN_PATH}/avr-gcc${EXECUTABLE_SUFFIX}" CACHE FILEPATH "AVR C compiler")
    set(CMAKE_CXX_COMPILER "${AVR_BIN_PATH}/avr-g++${EXECUTABLE_SUFFIX}" CACHE FILEPATH "AVR C++ compiler")
    set(CMAKE_ASM_COMPILER "${AVR_BIN_PATH}/avr-gcc${EXECUTABLE_SUFFIX}" CACHE FILEPATH "AVR assembler")

    # Утилиты
    set(CMAKE_OBJCOPY "${AVR_BIN_PATH}/avr-objcopy" CACHE INTERNAL "")
    set(CMAKE_SIZE    "${AVR_BIN_PATH}/avr-size"    CACHE INTERNAL "")
    set(CMAKE_OBJDUMP "${AVR_BIN_PATH}/avr-objdump" CACHE INTERNAL "")

    # Sysroot для поиска библиотек и заголовков
    set(CMAKE_FIND_ROOT_PATH "${AVR_ROOT_PATH}")
    set(CMAKE_SYSROOT "${AVR_ROOT_PATH}")
    set(CMAKE_SYSROOT "${AVR_ROOT_PATH}")

    message(STATUS "Using AVR toolchain from: ${AVR_ROOT_PATH}")
else ()
    # Fallback: ищем в PATH
    set(CMAKE_C_COMPILER   avr-gcc)
    set(CMAKE_CXX_COMPILER avr-g++)
    set(CMAKE_ASM_COMPILER avr-gcc)
    set(CMAKE_OBJCOPY avr-objcopy CACHE INTERNAL "")
    set(CMAKE_SIZE    avr-size    CACHE INTERNAL "")
    set(CMAKE_OBJDUMP avr-objdump CACHE INTERNAL "")

    message(STATUS "Using AVR toolchain from PATH")
endif()

# Avrdude может быть отдельно установлен
find_program(CMAKE_AVRDUDE avrdude)
if (NOT CMAKE_AVRDUDE)
    set(CMAKE_AVRDUDE avrdude CACHE INTERNAL "")
endif()

# Настройки поиска
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# System include / lib paths
if (DEFINED CMAKE_FIND_ROOT_PATH)
    set(CMAKE_SYSTEM_INCLUDE_PATH "${CMAKE_FIND_ROOT_PATH}/include" CACHE INTERNAL "")
    set(CMAKE_SYSTEM_LIBRARY_PATH "${CMAKE_FIND_ROOT_PATH}/lib" CACHE INTERNAL "")
endif()

# Make try-compile produce STATIC libs
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)