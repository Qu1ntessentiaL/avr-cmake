# cmake/avr-platform.cmake
# Defines an INTERFACE library "avr_platform" that carries MCU, F_CPU and
# compiler/linker options. Include this from the root CMakeLists.

if (NOT DEFINED AVR_MCU)
    message(FATAL_ERROR "AVR_MCU is not set. Set it before including avr-platform.cmake (e.g. atmega128a).")
endif()

if (NOT DEFINED F_CPU)
    message(FATAL_ERROR "F_CPU is not set. Set it before including avr-platform.cmake (e.g. 7372800UL).")
endif()

add_library(avr_platform INTERFACE)

# compiler flags (interface)
target_compile_options(avr_platform INTERFACE
        -mmcu=${AVR_MCU}
        -Os
        -Wall
        -Wextra
        -Wno-main
        -Wstrict-overflow=5
        -Winline
        -fstrict-overflow
        -fno-strict-aliasing
        -ffunction-sections
        -fdata-sections
        # -fno-exceptions
        # -fno-rtti
)

# definitions
target_compile_definitions(avr_platform INTERFACE
        F_CPU=${F_CPU}
)

# linker flags
target_link_options(avr_platform INTERFACE
        -mmcu=${AVR_MCU}
        -Wl,--gc-sections
        -Wl,-Map=${CMAKE_PROJECT_NAME}.map
)
