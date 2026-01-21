#include <avr/interrupt.h>
#include <util/delay.h>

#include "gpio.hpp"
#include "usart.hpp"

#include "ch.h"

using namespace GPIO;
using namespace UART;

using LED_G = Pin<Port::D, 0>;

// Частота системного таймера (Hz)
#define SYS_TICK_FREQ 1000

// Расчет для 7.3728 MHz
#if F_CPU == 7372800UL
    // Для делителя 64: 7372800 / (64 * 1000) - 1 = 114.2
    #define TIMER_COMPARE 114
#endif

// Обработчик прерывания таймера
ISR(TIMER1_COMPA_vect) {
    chSysLockFromISR();
    chSysTimerHandlerI();
    chSysUnlockFromISR();
}

/*
 * Thread 1.
 */
THD_WORKING_AREA(waThread1, 128);
THD_FUNCTION(Thread1, arg) {
    (void) arg;

    while (true) {
        LED_G::toggle();
        chThdSleepMilliseconds(1000);
    }
}

/*
 * Thread 2.
 */
THD_WORKING_AREA(waThread2, 256);
THD_FUNCTION(Thread2, arg) {
    (void) arg;

    uint32_t counter = 0;

    while (true) {
        UART0::print("Counter: ");
        UART0::print(counter++);
        UART0::print("\r\n");
        chThdSleepMilliseconds(2000);
    }
}

/*
 * Threads static table, one entry per thread. The number of entries must
 * match NIL_CFG_NUM_THREADS.
 */
THD_TABLE_BEGIN
    THD_TABLE_THREAD(0, "blinker", waThread1, Thread1, NULL)
    THD_TABLE_THREAD(1, "hello", waThread2, Thread2, NULL)
THD_TABLE_END

static void init_sys_timer() {
    // Timer1 в режиме CTC (сравнение с OCR1A)
    TCCR1B = 0;
    TCCR1A = 0;

    // Режим CTC (WGM12 = 1)
    TCCR1B |= (1 << WGM12);

    // Делитель 64 (CS11 = 1, CS10 = 1)
    TCCR1B |= (1 << CS11) | (1 << CS10);

    // Значение сравнения для 1kHz при 16MHz
    OCR1A = TIMER_COMPARE;

    // Разрешаем прерывание по совпадению
    TIMSK |= (1 << OCIE1A);

    // Сбрасываем счетчик
    TCNT1 = 0;
}

/*
 * Application entry point.
 */
int main() {
    LED_G::init(Direction::Output,
                Pull::None,
                Level::High);

    // Настройка Timer1
    TCCR1B |= (1 << WGM12); // CTC mode (сравнение с OCR1A)
    OCR1A = 14; // Значение, до которого считает счетчик
    TCCR1B |= (1 << WGM12) | (1 << CS12) | (1 << CS10); // Делитель = 1024
    TIMSK |= (1 << OCIE1A); // Разрешаем прерывание по совпадению OCR1A

    // Конфигурация UART0
    Config uart_config;
    uart_config.baud_rate = BaudRate::B115200;
    uart_config.data_bits = DataBits::Eight;
    uart_config.stop_bits = StopBits::One;
    uart_config.parity = Parity::None;
    uart_config.double_speed = false;

    // Инициализация
    UART0::init(uart_config);

    sei(); // Включаем глобальные прерывания
    chSysInit();

    while (true) {
        chThdSleepMilliseconds(500);
    }
}
