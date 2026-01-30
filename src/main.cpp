#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <avr/io.h>

#include "gpio.hpp"
#include "usart.hpp"

using namespace GPIO;
using namespace UART;

using LED_G = Pin<Port::D, 0>;

// Обработчик прерывания таймера
ISR(TIMER1_COMPA_vect) {
    LED_G::toggle();
}

int main() {
    LED_G::init(Direction::Output,
                Pull::None,
                Level::High);

    TCCR1A = 0;
    TCCR1B = (1 << WGM12) | (1 << CS12) | (1 << CS10);
    OCR1A = (F_CPU / 1024) - 1;
    TIMSK |= (1 << OCIE1A);

    // Конфигурация UART0
    Config uart_config;
    uart_config.baud_rate = BaudRate::B115200;
    uart_config.data_bits = DataBits::Eight;
    uart_config.stop_bits = StopBits::One;
    uart_config.parity = Parity::None;
    uart_config.double_speed = false;

    // Инициализация
    UART0::init(uart_config);
    UART0::print("Hello, ATmega128!\r\n");

    sei();

    while (true) {}
}
