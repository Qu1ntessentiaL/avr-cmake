#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <avr/io.h>

// Обработчик прерывания таймера
ISR(TIMER1_COMPA_vect) {
    PORTD ^= (1 << PD0);
}

int main() {
    DDRD |= (1 << PD0);

    TCCR1A = 0;
    TCCR1B = (1 << WGM12) | (1 << CS12) | (1 << CS10);
    OCR1A = (F_CPU / 1024) - 1;
    TIMSK |= (1 << OCIE1A);

    sei();

    while (true) {}
}
