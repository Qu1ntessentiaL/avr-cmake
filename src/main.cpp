#include <avr/interrupt.h>
#include <util/delay.h>

#include "gpio.hpp"
#include "usart.hpp"

using namespace GPIO;
using namespace UART;

using LED_Y = Pin<Port::E, 0>;
using LED_G = Pin<Port::D, 0>;

// Обработчик прерывания таймера
ISR(TIMER1_COMPA_vect) {
    LED_Y::toggle();
    PORTD ^= (1 << PD0);
}

int main() {
    LED_Y::init(Direction::Output,
                Pull::None,
                Level::Low);

    LED_G::init(Direction::Output,
                Pull::None,
                Level::High);

    // Настройка Timer1
    TCCR1B |= (1 << WGM12);              // CTC mode (сравнение с OCR1A)
    OCR1A = F_CPU >> 12;                 // Значение, до которого считает счетчик
    TCCR1B |= (1 << CS12) | (1 << CS10); // Делитель = 1024
    TIMSK |= (1 << OCIE1A);              // Разрешаем прерывание по совпадению OCR1A

    // Конфигурация UART0
    Config uart_config;
    uart_config.baud_rate = BaudRate::B115200;
    uart_config.data_bits = DataBits::Eight;
    uart_config.stop_bits = StopBits::One;
    uart_config.parity = Parity::None;
    uart_config.double_speed = false;

    // Инициализация
    UART0::init(uart_config);

    // Включаем прерывания (опционально)
    sei();

    // Отправка строки
    UART0::print("Hello, ATmega128!\r\n");

    // Отправка числа
    uint32_t counter = 0;

    sei(); // Включаем глобальные прерывания

    while (true) {
        UART0::print("Counter: ");
        UART0::print(counter++);
        UART0::print("\r\n");

        // Чтение с эхом
        if (UART0::available()) {
            uint8_t data = UART0::get();
            UART0::put(data); // Эхо
        }

        _delay_ms(1000);
    }
}
