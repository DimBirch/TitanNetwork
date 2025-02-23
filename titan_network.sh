#!/bin/bash
# Перевірка, чи скрипт запущено від імені користувача root
if [ "$(id -u)" != "0" ]; then
    echo "Цей скрипт необхідно запускати з правами користувача root."
    echo "Будь ласка, спробуйте скористатися командою 'sudo -i', щоб перейти до користувача root, а потім запустіть цей скрипт знову."
    exit 1
fi

echo "=======================Вузол Titan=======================" 

echo "░▒▓████████▓▒░░▒▓██████▓▒░ ░▒▓███████▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░░▒▓████████▓▒░"
echo "░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░"
echo "░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░"
echo "░▒▓██████▓▒░ ░▒▓████████▓▒░░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓██████▓▒░"
echo "░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░  ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░"
echo "░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░  ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░"
echo "░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░   ░▒▓█▓▒░    ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░"                                                                                             
echo ""
echo "Не забудьте приєднатися до нашого офіційного каналу:"
echo "Telegram: https://t.me/EASYONEUA"
echo "Репозиторій Github: https://github.com/DimBirch/"

read -p "Введіть ваш ідентифікаційний код: " id

# Дозволяємо користувачу ввести кількість контейнерів, які потрібно створити
read -p "Будь ласка, введіть кількість вузлів, які потрібно створити. Одна IP обмежена максимум 5 вузлами: " container_count

# Дозволяємо користувачу ввести обмеження розміру жорсткого диска для кожного вузла (в ГБ)
read -p "Будь ласка, введіть обмеження розміру жорсткого диска для кожного вузла (в ГБ, наприклад: 1 означає 1 ГБ, 2 означає 2 ГБ): " disk_size_gb 

# Запитуємо директорію для зберігання даних користувача і задаємо значення за замовчуванням
read -p "Будь ласка, введіть директорію для зберігання даних томів [за замовчуванням: /mnt/docker_volumes]: " volume_dir
volume_dir=${volume_dir:-/mnt/docker_volumes}

apt update

# Перевіряємо, чи встановлено Docker
if ! command -v docker &> /dev/null
then
    echo "Docker не виявлено, виконується встановлення..."
    apt-get install ca-certificates curl gnupg lsb-release
    
    # Встановлюємо останню версію Docker
    apt-get install docker.io -y
else
    echo "Docker уже встановлено."
fi

# Завантажуємо образ Docker
docker pull nezha123/titan-edge

# Створюємо директорію для зберігання файлів образів
mkdir -p $volume_dir

# Створюємо задану користувачем кількість контейнерів
for i in $(seq 1 $container_count)
do
    disk_size_mb=$((disk_size_gb * 1024))
    
    # Створюємо файловий образ із заданим розміром для кожного контейнера
    volume_path="$volume_dir/volume_$i.img"
    sudo dd if=/dev/zero of=$volume_path bs=1M count=$disk_size_mb
    sudo mkfs.ext4 $volume_path

    # Створюємо директорію та монтуємо файлову систему
    mount_point="/mnt/my_volume_$i"
    mkdir -p $mount_point
    sudo mount -o loop $volume_path $mount_point

    # Додаємо інформацію до /etc/fstab для автоматичного монтування
    echo "$volume_path $mount_point ext4 loop,defaults 0 0" | sudo tee -a /etc/fstab

    # Запускаємо контейнер із політикою перезапуску "завжди"
    container_id=$(docker run -d --restart always -v $mount_point:/root/.titanedge/storage --name "titan$i" nezha123/titan-edge)

    echo "Вузол titan$i запущено, ID контейнера: $container_id"

    sleep 30
    
    # Виконуємо прив’язку в контейнері
    docker exec -it $container_id bash -c "\
        titan-edge bind --hash=$id https://api-test1.container1.titannet.io/api/v2/device/binding"
done

echo "==============================Усі вузли налаштовано та запущено===================================."
