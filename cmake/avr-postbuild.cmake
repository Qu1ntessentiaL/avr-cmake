# cmake/avr-postbuild.cmake

# Modern AVR post-build utilities and analysis helpers

# Prefer tool definitions already set by the toolchain file, otherwise find them in PATH
if (DEFINED CMAKE_OBJCOPY AND CMAKE_OBJCOPY)
    set(AVR_OBJCOPY ${CMAKE_OBJCOPY})
else()
    find_program(AVR_OBJCOPY avr-objcopy)
endif()

if (DEFINED CMAKE_SIZE AND CMAKE_SIZE)
    set(AVR_SIZE ${CMAKE_SIZE})
else()
    find_program(AVR_SIZE avr-size)
endif()

if (DEFINED CMAKE_OBJDUMP AND CMAKE_OBJDUMP)
    set(AVR_OBJDUMP ${CMAKE_OBJDUMP})
else()
    find_program(AVR_OBJDUMP avr-objdump)
endif()

if (DEFINED CMAKE_OBJDUMP AND CMAKE_OBJDUMP)
    # reuse above
else()
    # already set via find_program
endif()

if (DEFINED CMAKE_NM AND CMAKE_NM)
    set(AVR_NM ${CMAKE_NM})
else()
    find_program(AVR_NM avr-nm)
endif()

find_program(AVR_AVRDUDE avrdude)

if (NOT AVR_OBJCOPY)
    message(FATAL_ERROR "avr-postbuild: avr-objcopy not found; please install avr-binutils or set CMAKE_OBJCOPY")
endif()
if (NOT AVR_SIZE)
    message(FATAL_ERROR "avr-postbuild: avr-size not found; please install avr-binutils or set CMAKE_SIZE")
endif()
if (NOT AVR_OBJDUMP)
    message(FATAL_ERROR "avr-postbuild: avr-objdump not found; please install avr-binutils or set CMAKE_OBJDUMP")
endif()

# Helper: write a small header used by multiple reports
function(fw_write_header OUT_FILE TITLE TARGET_NAME EXTRA_INFO)
    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "=================================================" > ${OUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E echo "${TITLE}" >> ${OUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E echo "Target: ${TARGET_NAME}" >> ${OUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E echo "Build type: ${CMAKE_BUILD_TYPE}" >> ${OUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E echo "ELF: $<TARGET_FILE:${TARGET_NAME}>" >> ${OUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E echo "Info: ${EXTRA_INFO}" >> ${OUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E echo "=================================================" >> ${OUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E echo "" >> ${OUT_FILE}
        VERBATIM
    )
endfunction()

# Primary: attach common post-build steps to a target (HEX, EEPROM, SIZE, DISASSEMBLY)
function(add_avr_post_build_commands TARGET_NAME)
    if (NOT TARGET_NAME)
        message(FATAL_ERROR "add_avr_post_build_commands: TARGET_NAME is required")
    endif()

    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "Post-build: Generating HEX, EEPROM, size and disassembly..."

        # HEX (without EEPROM)
        COMMAND ${AVR_OBJCOPY} -O ihex -R .eeprom $<TARGET_FILE:${TARGET_NAME}> ${TARGET_NAME}.hex

        # EEPROM image (if present)
        COMMAND ${AVR_OBJCOPY} -O ihex -j .eeprom --set-section-flags=.eeprom=alloc,load --change-section-lma .eeprom=0 $<TARGET_FILE:${TARGET_NAME}> ${TARGET_NAME}.eep

        # Size summary
        COMMAND ${AVR_SIZE} --radix=10 --common $<TARGET_FILE:${TARGET_NAME}>

        # Disassembly (human-readable)
        COMMAND ${AVR_OBJDUMP} -h -S $<TARGET_FILE:${TARGET_NAME}> > ${TARGET_NAME}.lss

        COMMENT "Post-build: HEX, EEPROM, SIZE, DISASSEMBLY"
        VERBATIM
    )
endfunction()

# Analysis: symbol sizes report
function(add_symbol_sizes_postbuild TARGET_NAME)
    set(OUT_FILE "${CMAKE_BINARY_DIR}/symbol_sizes_${TARGET_NAME}.txt")

    fw_write_header(
        ${OUT_FILE}
        "SYMBOL SIZE REPORT"
        ${TARGET_NAME}
        "Sorted by size (descending)"
    )

    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
        COMMAND ${AVR_OBJCOPY} -R .comment $<TARGET_FILE:${TARGET_NAME}> tmp_${TARGET_NAME}.elf
        COMMAND ${AVR_NM} -S --size-sort -r tmp_${TARGET_NAME}.elf >> ${OUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E rm -f tmp_${TARGET_NAME}.elf
        COMMENT "Generating symbol size report for ${TARGET_NAME}"
        VERBATIM
    )
endfunction()

function(add_symbol_addresses_postbuild TARGET_NAME)
    set(OUT_FILE "${CMAKE_BINARY_DIR}/symbol_addresses_${TARGET_NAME}.txt")

    fw_write_header(
        ${OUT_FILE}
        "SYMBOL ADDRESS REPORT"
        ${TARGET_NAME}
        "Sorted by memory address"
    )

    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
        COMMAND ${AVR_OBJCOPY} -R .comment $<TARGET_FILE:${TARGET_NAME}> tmp_${TARGET_NAME}.elf
        COMMAND ${AVR_NM} -S -n tmp_${TARGET_NAME}.elf >> ${OUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E rm -f tmp_${TARGET_NAME}.elf
        COMMENT "Generating symbol address report for ${TARGET_NAME}"
        VERBATIM
    )
endfunction()

# Target to show .text section entries
function(add_text_info_target TARGET_NAME)
    if(WIN32)
        set(GREP_CMD findstr)
    else()
        set(GREP_CMD grep)
    endif()

    add_custom_target(text_info_${TARGET_NAME}
        COMMAND ${CMAKE_COMMAND} -E echo ".text Section for ${TARGET_NAME}"
        COMMAND ${AVR_OBJDUMP} -t $<TARGET_FILE:${TARGET_NAME}> | ${GREP_CMD} ".text"
        DEPENDS ${TARGET_NAME}
        COMMENT "Analyzing .text section for ${TARGET_NAME}"
        VERBATIM
    )
endfunction()

# Flash operations using avrdude (if available)
function(add_erase_flash_target)
    if (NOT AVR_AVRDUDE)
        message(WARNING "avrdude not found; erase_flash target will be unavailable")
        return()
    endif()

    if (NOT DEFINED AVR_PROGRAMMER)
        set(AVR_PROGRAMMER "usbasp")
    endif()
    if (NOT DEFINED AVR_PORT)
        set(AVR_PORT "usb")
    endif()

    add_custom_target(erase_flash
        COMMAND ${CMAKE_COMMAND} -E echo "Erasing flash memory..."
        COMMAND ${AVR_AVRDUDE} -c ${AVR_PROGRAMMER} -p ${AVR_MCU} -P ${AVR_PORT} -e
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Erasing AVR flash"
        VERBATIM
    )
endfunction()

function(add_flash_target TARGET_NAME)
    if (NOT AVR_AVRDUDE)
        message(WARNING "avrdude not found; flash target will be unavailable")
        return()
    endif()
    if (NOT TARGET_NAME)
        message(FATAL_ERROR "add_flash_target: TARGET_NAME is required")
    endif()
    if (NOT DEFINED AVR_PROGRAMMER)
        set(AVR_PROGRAMMER "usbasp")
    endif()
    if (NOT DEFINED AVR_PORT)
        set(AVR_PORT "usb")
    endif()

    add_custom_target(flash_${TARGET_NAME}
        COMMAND ${CMAKE_COMMAND} -E echo "Flashing firmware ${TARGET_NAME}..."
        COMMAND ${AVR_AVRDUDE} -c ${AVR_PROGRAMMER} -p ${AVR_MCU} -P ${AVR_PORT} -U flash:w:${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.hex:i
        DEPENDS ${TARGET_NAME}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Flashing ${TARGET_NAME} to AVR"
        VERBATIM
    )
endfunction()

message(STATUS "avr-postbuild: loaded AVR post-build helpers")
