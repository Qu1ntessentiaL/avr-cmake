#include <avr/interrupt.h>
#include <util/delay.h>

#include "gpio.hpp"

using namespace GPIO;

using LED = Pin<Port::E, 0>;

// Обработчик прерывания таймера
ISR(TIMER1_COMPA_vect) {
    LED::toggle();
}

int main() {
    LED::init(Direction::Output,
              Pull::None,
              Level::Low); // Настраиваем PE0 как выход

    // Настройка Timer1
    TCCR1B |= (1 << WGM12);              // CTC mode (сравнение с OCR1A)
    OCR1A = F_CPU >> 12;                 // Значение, до которого считает счетчик
    TCCR1B |= (1 << CS12) | (1 << CS10); // Делитель = 1024
    TIMSK |= (1 << OCIE1A);              // Разрешаем прерывание по совпадению OCR1A

    sei(); // Включаем глобальные прерывания

    while (true) {
        // Основной цикл пустой — всё делает прерывание
    }
}
