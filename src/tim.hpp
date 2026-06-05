#pragma once

template<uint32_t Fcpu>
class Timer1 {
public:
    enum class Prescaler : uint8_t {
        Stop = 0,
        Div1 = (1 << CS10),
        Div8 = (1 << CS11),
        Div64 = (1 << CS11) | (1 << CS10),
        Div256 = (1 << CS12),
        Div1024 = (1 << CS12) | (1 << CS10)
    };

    static void stop() {
        TCCR1B &= ~((1 << CS12) | (1 << CS11) | (1 << CS10));
    }

    static void ctc(Prescaler prescaler) {
        TCCR1A = 0;

        TCCR1B = (1 << WGM12) | static_cast<uint8_t>(prescaler);
    }

    static void normal(Prescaler prescaler) {
        TCCR1A = 0;

        TCCR1B = static_cast<uint8_t>(prescaler);
    }

    static void compareA(uint16_t value) {
        OCR1A = value;
    }

    static void counter(uint16_t value) {
        TCNT1 = value;
    }

    static uint16_t counter() {
        return TCNT1;
    }

    static void enableCompareAInterrupt() {
        TIMSK |= (1 << OCIE1A);
    }

    static void disableCompareAInterrupt() {
        TIMSK &= ~(1 << OCIE1A);
    }

    static void enableOverflowInterrupt() {
        TIMSK |= (1 << TOIE1);
    }

    static void disableOverflowInterrupt() {
        TIMSK &= ~(1 << TOIE1);
    }

    static constexpr uint16_t compareFor1Hz() {
        return (Fcpu >> 10) - 1;
    }

    static constexpr uint16_t compareForFrequency(uint32_t frequency,
                                                  uint32_t prescaler) {
        return (Fcpu / prescaler / frequency) - 1;
    }
};
