#!/bin/bash
# Функция для переключения версий AVR компилятора

# Удаляем все пути AVR из PATH
clean_avr_path() {
    # Метод 1: Безопасное удаление через цикл
    local new_path=""
    IFS=':' read -ra ADDR <<< "$PATH"
    for dir in "${ADDR[@]}"; do
        # Пропускаем пути, содержащие avr-gcc
        if [[ "$dir" != *"avr-gcc"* ]] && [[ "$dir" != *"/avr/bin"* ]]; then
            new_path="${new_path}:${dir}"
        fi
    done
    export PATH="${new_path#:}"

    # Метод 2: Альтернативный способ через sed (более агрессивный)
    # export PATH=$(echo "$PATH" | sed -E 's|:[^:]*avr-gcc[^:]*||g; s|^[^:]*avr-gcc[^:]*:?||; s|^:*||; s|:*$||')
}

# Основная функция переключения
switch_avr() {
    local version="${1:-15}"  # По умолчанию версия 15
    local avr_path=""
    local version_name=""

    # Очищаем PATH от старых путей AVR
    clean_avr_path

    # Определяем путь в зависимости от версии
    case "$version" in
        5|5.4|old|avr5)
            avr_path="/opt/avr-gcc/avr8-gnu-toolchain-linux_x86_64_old/bin"
            version_name="5.4.0 (old)"
            ;;
        15|15.1|new|avr15|latest)
            avr_path="/opt/avr-gcc/avr8-gnu-toolchain-linux_x86_64/bin"
            version_name="15.1.0 (latest)"
            ;;
        *)
            echo "Неизвестная версия: $version"
            echo "Доступные версии:"
            echo "  5, 5.4, old   - GCC 5.4.0 (old)"
            echo "  15, 15.1, new - GCC 15.1.0 (latest)"
            return 1
            ;;
    esac

    # Проверяем существование пути и добавляем в PATH
    if [ -d "$avr_path" ]; then
        export PATH="$avr_path:$PATH"
        echo "✅ Переключено на AVR GCC $version_name"
        echo "📁 Путь: $avr_path"

        # Проверяем, что компилятор доступен
        if command -v avr-gcc >/dev/null 2>&1; then
            echo "🔧 Версия компилятора:"
            avr-gcc --version | head -n1
        else
            echo "⚠️  Предупреждение: avr-gcc не найден после добавления в PATH"
        fi
    else
        echo "❌ Путь не найден: $avr_path"
        echo "Проверьте установку AVR toolchain"
        return 1
    fi
}

# Алиасы для быстрого переключения
alias avr5='switch_avr 5'
alias avr-old='switch_avr old'
alias avr15='switch_avr 15'
alias avr-new='switch_avr new'
alias avr-latest='switch_avr latest'

# Показать текущую версию AVR
avr-version() {
    if command -v avr-gcc >/dev/null 2>&1; then
        echo "📋 Текущая версия AVR GCC:"
        avr-gcc --version | head -n1
        echo "📍 Расположение: $(which avr-gcc)"

        # Определяем, какая версия активна по пути
        local gcc_path=$(which avr-gcc)
        if [[ "$gcc_path" == *"_old"* ]]; then
            echo "🎯 Активна: Версия 5.4.0 (old)"
        elif [[ "$gcc_path" == *"avr8-gnu-toolchain-linux_x86_64"* ]]; then
            echo "🎯 Активна: Версия 15.1.0 (latest)"
        fi
    else
        echo "❌ AVR GCC не найден в PATH"
        echo "Используйте: switch_avr [5|15]"
    fi
}

# Показать все доступные версии AVR
avr-list() {
    echo "📚 Доступные версии AVR:"
    echo ""
    echo "1. Версия 5.4.0 (old):"
    echo "   Путь: /opt/avr-gcc/avr8-gnu-toolchain-linux_x86_64_old/bin"
    if [ -d "/opt/avr-gcc/avr8-gnu-toolchain-linux_x86_64_old/bin" ]; then
        echo "   ✅ Установлена"
    else
        echo "   ❌ Не установлена"
    fi
    echo ""
    echo "2. Версия 15.1.0 (latest):"
    echo "   Путь: /opt/avr-gcc/avr8-gnu-toolchain-linux_x86_64/bin"
    if [ -d "/opt/avr-gcc/avr8-gnu-toolchain-linux_x86_64/bin" ]; then
        echo "   ✅ Установлена"
    else
        echo "   ❌ Не установлена"
    fi
    echo ""
    echo "Команды:"
    echo "  avr5, avr-old     - переключить на версию 5.4.0"
    echo "  avr15, avr-new    - переключить на версию 15.1.0"
    echo "  avr-version       - показать текущую версию"
    echo "  avr-list          - показать все доступные версии"
}

# Инициализация: показываем текущую версию при загрузке
echo "🛠️  AVR Toolchain Manager загружен"
echo "Используйте 'avr-list' для списка команд"