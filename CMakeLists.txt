cmake_minimum_required(VERSION 3.20)

set(CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL "" FORCE)

# ---------------------------
# Project
# ---------------------------
project(blink LANGUAGES C CXX ASM)

# ---------------------------
# MCU / Platform configuration (пользователь может перекрыть через -D)
# ---------------------------
if (NOT DEFINED AVR_MCU)
    set(AVR_MCU atmega128a CACHE STRING "MCU for AVR toolchain (e.g. atmega128a)")
endif ()
if (NOT DEFINED AVR_MCU_PRG)
    set(AVR_MCU_PRG m128 CACHE STRING "MCU ID used by avrdude (e.g. m128)")
endif ()
if (NOT DEFINED F_CPU)
    set(F_CPU 7372800UL CACHE STRING "CPU frequency")
endif ()
if (NOT DEFINED AVR_PROGRAMMER)
    set(AVR_PROGRAMMER usbasp CACHE STRING "Programmer for avrdude (e.g. usbasp)")
endif ()
if (NOT DEFINED AVR_UPLOADTOOL)
    set(AVR_UPLOADTOOL avrdude CACHE STRING "Upload tool (avrdude)")
endif ()

# ---------------------------
# Build type
# ---------------------------
if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif ()

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
endforeach ()
list(REMOVE_DUPLICATES INCLUDE_DIRS)

# Optionally add vendor/include (same as original: "${AVR_DFP}/include")
if (DEFINED ENV{AVR_DFP})
    list(APPEND INCLUDE_DIRS "$ENV{AVR_DFP}/include")
endif ()

# apply includes to target later

# ---------------------------
# Platform (include AFTER we set AVR_MCU and F_CPU)
# ---------------------------
include("${CMAKE_SOURCE_DIR}/cmake/avr-platform.cmake")

# ---------------------------
# Create executable (ELF)
# ---------------------------
add_executable(${PROJECT_NAME}
        ${SRC_FILES}
)

set_target_properties(${PROJECT_NAME} PROPERTIES
        OUTPUT_NAME "${PROJECT_NAME}.elf"
)

# include directories
if (INCLUDE_DIRS)
    target_include_directories(${PROJECT_NAME} PRIVATE ${INCLUDE_DIRS})
endif ()

# Link to platform
target_link_libraries(${PROJECT_NAME} PRIVATE avr_platform)

# ---------------------------
# Ensure map file is produced (map name set by avr_platform via -Wl,-Map=...)
# ---------------------------
# Note: avr_platform already requested a map named ${CMAKE_PROJECT_NAME}.map

# ---------------------------
# Add optional ChibiOS (uncomment when ChibiOS present)
# ---------------------------
# add_subdirectory(libs/ChibiOS)
#
# target_link_libraries(${PROJECT_NAME}.elf PRIVATE chibios-nil)
# target_compile_options(chibios-nil PRIVATE
#         -mmcu=atmega128a
# )
# ---------------------------
# Post-build hooks (HEX, EEP, SIZE, DISASM)
# ---------------------------
include("${CMAKE_SOURCE_DIR}/cmake/avr-postbuild.cmake")
avr_post_build(${PROJECT_NAME})

# ---------------------------
# Flash target using avrdude
# ---------------------------
add_custom_target(flash
        COMMAND ${AVR_UPLOADTOOL}
        -p ${AVR_MCU_PRG}
        -c ${AVR_PROGRAMMER}
        -U flash:w:${PROJECT_NAME}.hex
        DEPENDS ${PROJECT_NAME}
        COMMENT "Flashing ${PROJECT_NAME}.hex to device"
)

# ---------------------------
# Erase target using avrdude
# ---------------------------
add_custom_target(erase
        COMMAND ${AVR_UPLOADTOOL}
        -p ${AVR_MCU_PRG}
        -c ${AVR_PROGRAMMER}
        -e
        COMMENT "Chip erase"
)
