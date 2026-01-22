#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <avr/io.h>
#include <util/delay.h>

#include "gpio.hpp"
#include "usart.hpp"

using namespace GPIO;
using namespace UART;

using LED_G = Pin<Port::D, 0>;

// Обработчик прерывания таймера
extern "C" __attribute__((used))
ISR(TIMER1_COMPA_vect) {
    PORTD ^= (1 << 0);
}

int main() {
    DDRD |= (1 << PD0);

    TCCR1A = 0;
    TCCR1B = (1 << WGM12) | (1 << CS12) | (1 << CS10);
    OCR1A = (F_CPU / 1024) - 1;
    TIMSK |= (1 << OCIE1A);

    sei();

    while (1) {}
}
