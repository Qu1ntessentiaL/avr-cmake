# Тестовый репозиторий программирования 8-bit микроконтроллеров AVR с использованием CMake

Настройка среды:
1. Скачать AVR 8-Bit Toolchain (Windows)
https://www.microchip.com/en-us/tools-resources/develop/microchip-studio/gcc-compilers;
2. Распаковать архив в диск C;
3. Создать переменную среды **AVR_FIND_ROOT_PATH** со значением пути к toolchain
(например C:\avr8-gnu-toolchain-win32_x86_64\avr);
4. Это можно сделать через PowerShell `[System.Environment]::SetEnvironmentVariable("AVR_FIND_ROOT_PATH", "C:\avr8-gnu-toolchain-win32_x86_64\avr", "User")`, где<br>
**"User"** - только для текущего пользователя,<br>
**"Machine"** - для всех пользователей (требуются права администратора);
5. Проверить с помощью `echo $env:AVR_FIND_ROOT_PATH`;