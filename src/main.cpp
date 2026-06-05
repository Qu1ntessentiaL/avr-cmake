#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <avr/io.h>

#include "gpio.hpp"
#include "usart.hpp"
#include "tim.hpp"

using namespace GPIO;
using namespace UART;

using LED_G = Pin<Port::D, 0>;
using tim1 = Timer1<F_CPU>;

// Обработчик прерывания таймера
ISR(TIMER1_COMPA_vect) {
    LED_G::toggle();
}

int main() {
    LED_G::init(Direction::Output,
                Pull::None,
                Level::High);

    tim1::ctc(tim1::Prescaler::Div1024);
    tim1::compareA(tim1::compareFor1Hz());
    tim1::enableCompareAInterrupt();

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
