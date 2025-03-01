# Определяем цвета для удобства
YELLOW="\e[33m"
CYAN="\e[36m"
BLUE="\e[34m"
GREEN="\e[32m"
RED="\e[31m"
PINK="\e[35m"
NC="\e[0m"


# Вывод приветственного текста с помощью figlet
echo -e "${RED}$(figlet -w 150 -f standard "SenseiCryptoX")${NC}"

echo "===================================================================================================================================="
echo "Добро пожаловать! Начинаем установку необходимых библиотек, пока подпишись на наш Telegram-канал"
echo ""
echo "SenseiCryptoX - https://t.me/SenseiCryptoX$"
echo "===================================================================================================================================="

echo ""

# Определение функции анимации
animate_loading() {
    for ((i = 1; i <= 5; i++)); do
        printf "\r${GREEN}Подгружаем меню${NC}."
        sleep 0.3
        printf "\r${GREEN}Подгружаем меню${NC}.."
        sleep 0.3
        printf "\r${GREEN}Подгружаем меню${NC}..."
        sleep 0.3
        printf "\r${GREEN}Подгружаем меню${NC}"
        sleep 0.3
    done
    echo ""
}

# Вызов функции анимации
animate_loading
echo ""

# Функция для установки ноды
install_node() {
    echo 'Начинаю установку...'

  read -p "Введите ваш приватный ключ: " PRIVATE_KEY
  echo $PRIVATE_KEY > $HOME/my.pem

  session="hyperspacenode"

  cd $HOME

  sudo apt-get update -y && sudo apt-get upgrade -y
  sudo apt-get install wget make tar screen nano libssl3-dev build-essential unzip lz4 gcc git jq -y

  if [ -d "$HOME/.aios" ]; then
    sudo rm -rf "$HOME/.aios"
    aios-cli kill
  fi
  
  if screen -list | grep -q "\.${session}"; then
    screen -S hyperspacenode -X quit
  else
    echo "Сессия ${session} не найдена."
  fi

  while true; do
    curl -s https://download.hyper.space/api/install | bash | tee $HOME/hyperspacenode_install.log

    if ! grep -q "Failed to parse version from release data." $HOME/hyperspacenode_install.log; then
        echo "Клиент-скрипт был установлен."
        break
    else
        echo "Сервер установки клиента недоступен, повторим через 30 секунд..."
        sleep 30
    fi
  done

  rm hyperspacenode_install.log

  export PATH=$PATH:$HOME/.aios
  source ~/.bashrc

  eval "$(cat ~/.bashrc | tail -n +10)"

  screen -dmS hyperspacenode bash -c '
    echo "Начало выполнения скрипта в screen-сессии"

    aios-cli start

    exec bash
  '

  while true; do
    aios-cli models add hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf 2>&1 | tee $HOME/hyperspacemodel_download.log

    if grep -q "Download complete" $HOME/hyperspacemodel_download.log; then
        echo "Модель была установлен."
        break
    else
        echo "Сервер установки модели недоступен, повторим через 30 секунд..."
        sleep 30
    fi
  done

  rm hyperspacemodel_download.log

  aios-cli hive import-keys $HOME/my.pem
  aios-cli hive login
  aios-cli hive connect
}

# Функция для проверки статуса ноды
  screen -S hyperspacenode -X hardcopy /tmp/screen_log.txt && sleep 0.1 && tail -n 100 /tmp/screen_log.txt && rm /tmp/screen_log.txt
}

# Функция для проверки поинтов ноды
check_points() {
      aios-cli hive points
}
# Функция для рестарта
restart_node() {
    session="hyperspacenode"
  
  if screen -list | grep -q "\.${session}"; then
    screen -S "${session}" -p 0 -X stuff "^C"
    sleep 1
    screen -S "${session}" -p 0 -X stuff "aios-cli start --connect\n"
    echo "Нода была перезагружена."
  else
    echo "Сессия ${session} не найдена."
  fi
}

# Функция для удаления ноды
remove_node() {
    read -p 'Если уверены удалить ноду, введите любую букву (CTRL+C чтобы выйти): ' checkjust

  echo 'Начинаю удалять ноду...'

  screen -S hyperspacenode -X quit
  aios-cli kill
  aios-cli models remove hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf
  sudo rm -rf $HOME/.aios

  echo 'Нода была удалена.'
}

exit_from_script() {
  exit 0
}

# Основное меню
CHOICE=$(whiptail --title "Меню действий" \
    --menu "Выберите действие:" 15 50 6 \
    "1" "Установка ноды" \
    "2" "Проверка статуса ноды" \
    "3" "Проверка поинтов ноды" \
    "4" "Удаление ноды" \
    "5" "Перезагрузить ноду" \
    "6" "Выход" \
    3>&1 1>&2 2>&3)

case $CHOICE in
    1) 
        install_node
        ;;
    2) 
        check_status
        ;;
    3) 
        check_points
        ;;
    4) 
        remove_node
        ;;
    5)
        restart_node
        ;;
    6)
        echo -e "${CYAN}Выход из программы.${NC}"
        ;;
    *)
        echo -e "${RED}Неверный выбор. Завершение программы.${NC}"
        ;;
esac
