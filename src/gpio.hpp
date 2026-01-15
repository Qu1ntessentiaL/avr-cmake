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

    /** Port F */
    template<>
    struct PortRegs<Port::F> {
        static volatile uint8_t *port() { return &PORTF; }
        static volatile uint8_t *ddr() { return &DDRF; }
        static volatile uint8_t *pin() { return &PINF; }
    };

    /** Port G */
    template<>
    struct PortRegs<Port::G> {
        static volatile uint8_t *port() { return &PORTG; }
        static volatile uint8_t *ddr() { return &DDRG; }
        static volatile uint8_t *pin() { return &PING; }
    };

    /** GPIO flags */
    enum class Direction : uint8_t {
        Input,
        Output
    };

    enum class Pull : uint8_t {
        None,
        Up
    };

    enum class Level : uint8_t {
        Low,
        High
    };

    /** GPIO Pin */
    template<Port P, uint8_t Bit>
    class Pin {
        static_assert(Bit < 8, "GPIO pin bit must be 0..7");

        static constexpr uint8_t mask = (1 << Bit);

    public:
        static void init(Direction dir,
                         Pull pull = Pull::None,
                         Level level = Level::Low) {
            if (dir == Direction::Output) {
                *PortRegs<P>::ddr() |= mask;
                write(level);
            } else {
                *PortRegs<P>::ddr() &= ~mask;
                if (pull == Pull::Up)
                    *PortRegs<P>::port() |= mask;
                else
                    *PortRegs<P>::port() &= ~mask;
            }
        }

        static void output() { *PortRegs<P>::ddr() |= mask; }
        static void input() { *PortRegs<P>::ddr() &= ~mask; }

        static void high() { *PortRegs<P>::port() |= mask; }
        static void low() { *PortRegs<P>::port() &= ~mask; }

        static void toggle() { *PortRegs<P>::pin() = mask; }

        static bool read() {
            return (*PortRegs<P>::pin() & mask) != 0;
        }

        static void write(Level level) {
            (level == Level::High) ? high() : low();
        }
    };
}
