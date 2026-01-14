#pragma once

#include <stdint.h>
#include <avr/io.h>

namespace GPIO {
    enum class Port : uint8_t {
        A, B, C, D, E, F, G
    };

    template<Port P>
    struct PortRegs;

    /** Port A */
    template<>
    struct PortRegs<Port::A> {
        static volatile uint8_t *port() { return &PORTA; }
        static volatile uint8_t *ddr() { return &DDRA; }
        static volatile uint8_t *pin() { return &PINA; }
    };

    /** Port B */
    template<>
    struct PortRegs<Port::B> {
        static volatile uint8_t *port() { return &PORTB; }
        static volatile uint8_t *ddr() { return &DDRB; }
        static volatile uint8_t *pin() { return &PINB; }
    };

    /** Port C */
    template<>
    struct PortRegs<Port::C> {
        static volatile uint8_t *port() { return &PORTC; }
        static volatile uint8_t *ddr() { return &DDRC; }
        static volatile uint8_t *pin() { return &PINC; }
    };

    /** Port D */
    template<>
    struct PortRegs<Port::D> {
        static volatile uint8_t *port() { return &PORTD; }
        static volatile uint8_t *ddr() { return &DDRD; }
        static volatile uint8_t *pin() { return &PIND; }
    };

    /** Port E */
    template<>
    struct PortRegs<Port::E> {
        static volatile uint8_t *port() { return &PORTE; }
        static volatile uint8_t *ddr() { return &DDRE; }
        static volatile uint8_t *pin() { return &PINE; }
    };

    /** Pin */
    template<Port P, uint8_t Bit>
    class Pin {
        static_assert(Bit < 8, "GPIO pin bit must be 0..7");

    public:
        static inline void output() {
            *PortRegs<P>::ddr() |= (1 << Bit);
        }

        static inline void input() {
            *PortRegs<P>::ddr() &= ~(1 << Bit);
        }

        static inline void high() {
            *PortRegs<P>::port() |= (1 << Bit);
        }

        static inline void low() {
            *PortRegs<P>::port() &= ~(1 << Bit);
        }

        static inline void toggle() {
            *PortRegs<P>::pin() = (1 << Bit); // AVR toggle
        }

        static inline bool read() {
            return (*PortRegs<P>::pin() & (1 << Bit)) != 0;
        }
    };
}
