#pragma once

#include <stdint.h>
#include <avr/io.h>
#include <util/delay.h>

namespace UART {
    // Конфигурация скорости передачи
    enum class BaudRate : uint32_t {
        B2400 = 2400,
        B4800 = 4800,
        B9600 = 9600,
        B19200 = 19200,
        B38400 = 38400,
        B57600 = 57600,
        B115200 = 115200
    };

    // Конфигурация битов данных
    enum class DataBits : uint8_t {
        Five = 0,
        Six = 1,
        Seven = 2,
        Eight = 3,
        Nine = 7 // Только с parity = Even/Odd
    };

    // Конфигурация стоп-битов
    enum class StopBits : uint8_t {
        One = 0,
        Two = 1
    };

    // Конфигурация проверки четности
    enum class Parity : uint8_t {
        None = 0,
        Even = 2,
        Odd = 3
    };

    // Конфигурация UART
    struct Config {
        BaudRate baud_rate = BaudRate::B9600;
        DataBits data_bits = DataBits::Eight;
        StopBits stop_bits = StopBits::One;
        Parity parity = Parity::None;
        bool double_speed = false;
    };

    template<uint8_t UartNumber>
    class UART;

    // Специализация для UART0 (USART0)
    template<>
    class UART<0> {
        static constexpr uint8_t UCSRnA = 0x2B;   // UCSR0A
        static constexpr uint8_t UCSRnB = 0x2A;   // UCSR0B
        static constexpr uint8_t UCSRnC = 0x40;   // UCSR0C
        static constexpr uint8_t UBRRnL = 0x29;   // UBRR0L
        static constexpr uint8_t UBRRnH = 0x40;   // UBRR0H
        static constexpr uint8_t UDRn = 0x2C;     // UDR0

    public:
        // Инициализация UART0
        static void init(const Config &config = Config()) {
            // Вычисление UBRR
            uint32_t ubrr_value;
            if (config.double_speed) {
                ubrr_value = (F_CPU / (8UL * static_cast<uint32_t>(config.baud_rate))) - 1;
                UCSR0A = (1 << U2X0); // Включаем удвоение скорости
            } else {
                ubrr_value = (F_CPU / (16UL * static_cast<uint32_t>(config.baud_rate))) - 1;
                UCSR0A = 0;
            }

            // Установка скорости
            UBRR0H = static_cast<uint8_t>(ubrr_value >> 8);
            UBRR0L = static_cast<uint8_t>(ubrr_value);

            // Конфигурация формата кадра
            uint8_t ucsrc_config = 0;

            // Бит UCSZ0 и UCSZ1 в UCSR0B и UCSR0C
            uint8_t data_bits_val = static_cast<uint8_t>(config.data_bits);
            if (data_bits_val == 7) {
                // 9 бит
                ucsrc_config |= (1 << UCSZ00) | (1 << UCSZ01);
                UCSR0B |= (1 << UCSZ02);
            } else {
                ucsrc_config |= (data_bits_val << UCSZ00);
                UCSR0B &= ~(1 << UCSZ02);
            }

            // Стоп-биты
            ucsrc_config |= (static_cast<uint8_t>(config.stop_bits) << USBS0);

            // Четность
            ucsrc_config |= (static_cast<uint8_t>(config.parity) << UPM00);

            // Установка асинхронного режима (UMSEL00 = 0, UMSEL01 = 0)
            UCSR0C = ucsrc_config;

            // Включаем передатчик и приемник
            UCSR0B = (1 << RXEN0) | (1 << TXEN0);
        }

        // Отправка одного байта (блокирующая)
        static void put(uint8_t data) {
            // Ждем, пока буфер передачи не освободится
            while (!(UCSR0A & (1 << UDRE0)));

            // Отправляем данные
            UDR0 = data;
        }

        // Отправка строки (блокирующая)
        static void print(const char *str) {
            while (*str) {
                put(*str++);
            }
        }

        // Отправка числа (десятичное представление)
        static void print(uint32_t number) {
            char buffer[10];
            char *ptr = buffer + 9;
            *ptr = '\0';

            do {
                *--ptr = '0' + (number % 10);
                number /= 10;
            } while (number > 0);

            print(ptr);
        }

        // Прием одного байта (блокирующий)
        static uint8_t get() {
            // Ждем, пока данные не будут получены
            while (!(UCSR0A & (1 << RXC0)));

            // Читаем данные
            return UDR0;
        }

        // Проверка наличия данных для чтения
        static bool available() {
            return (UCSR0A & (1 << RXC0)) != 0;
        }

        // Чтение строки (до символа новой строки или максимальной длины)
        static void read_line(char *buffer, uint16_t max_length) {
            uint16_t i = 0;
            char c;

            while (i < max_length - 1) {
                c = get();

                if (c == '\r' || c == '\n') {
                    break;
                }

                buffer[i++] = c;

                // Эхо символа (опционально)
                put(c);
            }

            buffer[i] = '\0';
        }

        // Отключение UART
        static void disable() {
            UCSR0B = 0;
        }
    };

    // Специализация для UART1 (USART1) если доступен
    template<>
    class UART<1> {
        static constexpr uint8_t UCSRnA = 0xCB; // UCSR1A
        static constexpr uint8_t UCSRnB = 0xCA; // UCSR1B
        static constexpr uint8_t UCSRnC = 0xCC; // UCSR1C
        static constexpr uint8_t UBRRnL = 0xC9; // UBRR1L
        static constexpr uint8_t UBRRnH = 0xC8; // UBRR1H
        static constexpr uint8_t UDRn = 0xCE; // UDR1

    public:
        static void init(const Config &config = Config()) {
            // Аналогично UART0, но с другими регистрами
            uint32_t ubrr_value;
            if (config.double_speed) {
                ubrr_value = (F_CPU / (8UL * static_cast<uint32_t>(config.baud_rate))) - 1;
                UCSR1A = (1 << U2X1);
            } else {
                ubrr_value = (F_CPU / (16UL * static_cast<uint32_t>(config.baud_rate))) - 1;
                UCSR1A = 0;
            }

            UBRR1H = static_cast<uint8_t>(ubrr_value >> 8);
            UBRR1L = static_cast<uint8_t>(ubrr_value);

            uint8_t ucsrc_config = 0;
            uint8_t data_bits_val = static_cast<uint8_t>(config.data_bits);

            if (data_bits_val == 7) {
                // 9 бит
                ucsrc_config |= (1 << UCSZ10) | (1 << UCSZ11);
                UCSR1B |= (1 << UCSZ12);
            } else {
                ucsrc_config |= (data_bits_val << UCSZ10);
                UCSR1B &= ~(1 << UCSZ12);
            }

            ucsrc_config |= (static_cast<uint8_t>(config.stop_bits) << USBS1);
            ucsrc_config |= (static_cast<uint8_t>(config.parity) << UPM10);

            UCSR1C = ucsrc_config;
            UCSR1B = (1 << RXEN1) | (1 << TXEN1);
        }

        static void put(uint8_t data) {
            while (!(UCSR1A & (1 << UDRE1)));
            UDR1 = data;
        }

        static uint8_t get() {
            while (!(UCSR1A & (1 << RXC1)));
            return UDR1;
        }

        static bool available() {
            return (UCSR1A & (1 << RXC1)) != 0;
        }
    };

    // Псевдонимы для удобства
    using UART0 = UART<0>;
    using UART1 = UART<1>;
}
