# cmake/avr-postbuild.cmake

function(avr_post_build TARGET)
    if (NOT TARGET)
        message(FATAL_ERROR "avr_post_build: TARGET is required")
    endif()

    if (NOT DEFINED AVR_MCU)
        message(FATAL_ERROR "avr_post_build: AVR_MCU is not defined")
    endif()

    add_custom_command(TARGET ${TARGET} POST_BUILD
            # HEX
            COMMAND ${CMAKE_OBJCOPY}
            -O ihex
            -R .eeprom
            $<TARGET_FILE:${TARGET}>
            ${TARGET}.hex

            # EEPROM
            COMMAND ${CMAKE_OBJCOPY}
            -O ihex
            -j .eeprom
            --set-section-flags=.eeprom=alloc,load
            --change-section-lma .eeprom=0
            $<TARGET_FILE:${TARGET}>
            ${TARGET}.eep

            # SIZE
            COMMAND ${CMAKE_SIZE}
            --format=gnu
            --radix=10
            --common
            $<TARGET_FILE:${TARGET}>

            # DISASSEMBLY
            COMMAND ${CMAKE_OBJDUMP}
            -h -S
            $<TARGET_FILE:${TARGET}>
            > ${TARGET}.lss

            COMMENT "Post-build: HEX, EEPROM, SIZE, DISASSEMBLY"
            VERBATIM
    )
endfunction()
