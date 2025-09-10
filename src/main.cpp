#include <avr/io.h>
#include <util/delay.h>

int main() {
    // Настраиваем PE0 как выход
    DDRE |= (1 << PE0);

    while (1) {
        // Включаем LED
        PORTE |= (1 << PE0);
        _delay_ms(200);

        // Выключаем LED
        PORTE &= ~(1 << PE0);
        _delay_ms(200);
    }
}
