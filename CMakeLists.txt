cmake_minimum_required(VERSION 3.20)

# ---------------------------
# Project
# ---------------------------
project(blink LANGUAGES C CXX ASM)

# ---------------------------
# MCU / Platform configuration (пользователь может перекрыть через -D)
# ---------------------------
if (NOT DEFINED AVR_MCU)
    set(AVR_MCU atmega128a CACHE STRING "MCU for AVR toolchain (e.g. atmega128a)")
endif()
if (NOT DEFINED AVR_MCU_PRG)
    set(AVR_MCU_PRG m128 CACHE STRING "MCU ID used by avrdude (e.g. m128)")
endif()
if (NOT DEFINED F_CPU)
    set(F_CPU 7372800UL CACHE STRING "CPU frequency")
endif()
if (NOT DEFINED AVR_PROGRAMMER)
    set(AVR_PROGRAMMER usbasp CACHE STRING "Programmer for avrdude (e.g. usbasp)")
endif()
if (NOT DEFINED AVR_UPLOADTOOL)
    set(AVR_UPLOADTOOL avrdude CACHE STRING "Upload tool (avrdude)")
endif()

# ---------------------------
# If user passed a toolchain file, it will set CMAKE_OBJCOPY/CMAKE_SIZE etc.
# Otherwise include our default toolchain (optional)
# To force use our shipped toolchain call cmake with -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-avr-gcc.cmake
# ---------------------------
# (expect toolchain to be provided by user environment; otherwise include local)
if (NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    # Try to include our local toolchain (non-mandatory)
    if (EXISTS "${CMAKE_SOURCE_DIR}/cmake/toolchain-avr-gcc.cmake")
        include("${CMAKE_SOURCE_DIR}/cmake/toolchain-avr-gcc.cmake")
    endif()
endif()

# ---------------------------
# Build type
# ---------------------------
if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

message(STATUS "AVR MCU: ${AVR_MCU}")
message(STATUS "F_CPU: ${F_CPU}")
message(STATUS "Upload tool: ${AVR_UPLOADTOOL}, programmer: ${AVR_PROGRAMMER}")

# ---------------------------
# Sources discovery
# ---------------------------
file(GLOB_RECURSE SRC_FILES CONFIGURE_DEPENDS
        src/*.c
        src/*.cpp
        src/*.S
)

file(GLOB_RECURSE HEADER_FILES CONFIGURE_DEPENDS
        src/*.h
        src/*.hpp
)

# collect include dirs from headers
set(INCLUDE_DIRS "")
foreach (_h ${HEADER_FILES})
    get_filename_component(_dir ${_h} PATH)
    list(APPEND INCLUDE_DIRS ${_dir})
endforeach()
list(REMOVE_DUPLICATES INCLUDE_DIRS)

# Optionally add vendor/include (same as original: "${AVR_DFP}/include")
if (DEFINED ENV{AVR_DFP})
    list(APPEND INCLUDE_DIRS "$ENV{AVR_DFP}/include")
endif()

# apply includes to target later

# ---------------------------
# Platform (include AFTER we set AVR_MCU and F_CPU)
# ---------------------------
include("${CMAKE_SOURCE_DIR}/cmake/avr-platform.cmake")

# ---------------------------
# Create executable (ELF)
# ---------------------------
add_executable(${PROJECT_NAME}.elf ${SRC_FILES})

# include directories
if (INCLUDE_DIRS)
    target_include_directories(${PROJECT_NAME}.elf PRIVATE ${INCLUDE_DIRS})
endif()

# Link to platform
target_link_libraries(${PROJECT_NAME}.elf PRIVATE avr_platform)

# ---------------------------
# Ensure map file is produced (map name set by avr_platform via -Wl,-Map=...)
# ---------------------------
# Note: avr_platform already requested a map named ${CMAKE_PROJECT_NAME}.map

# ---------------------------
# Add optional ChibiOS (uncomment when ChibiOS present)
# ---------------------------
add_subdirectory(libs/ChibiOS)
# target_link_libraries(${PROJECT_NAME}.elf PRIVATE chibios-nil)

# ---------------------------
# Post-build hooks (HEX, EEP, SIZE, DISASM)
# ---------------------------
include("${CMAKE_SOURCE_DIR}/cmake/avr-postbuild.cmake")
avr_post_build(${PROJECT_NAME}.elf)

# ---------------------------
# Flash target using avrdude
# ---------------------------
add_custom_target(flash
        COMMAND ${AVR_UPLOADTOOL}
        -p ${AVR_MCU_PRG}
        -c ${AVR_PROGRAMMER}
        -U flash:w:${PROJECT_NAME}.elf.hex
        DEPENDS ${PROJECT_NAME}.elf
        COMMENT "Flashing ${PROJECT_NAME}.elf.hex to device"
)
