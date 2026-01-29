# Установка TrustTunnel с автозапуском на Keenetic

## Предварительные требования

Перед установкой на роутер необходимо:
1. Установить сервер TrustTunnel на VPS
2. Скачать клиент TrustTunnel для архитектуры вашего роутера

### 1. Установка сервера на VPS

На VPS с Linux (x86_64 или aarch64) выполните:

```bash
curl -fsSL https://raw.githubusercontent.com/TrustTunnel/TrustTunnel/refs/heads/master/scripts/install.sh | sh -s -
```

Сервер установится в `/opt/trusttunnel`. Запустите мастер настройки:

```bash
cd /opt/trusttunnel/
sudo ./setup_wizard
```

Мастер запросит:
- Адрес для прослушивания (по умолчанию `0.0.0.0:443`)
- Учетные данные пользователя
- Путь для хранения правил фильтрации
- Выбор сертификата (Let's Encrypt, самоподписанный или существующий)

Настройте автозапуск через systemd:

```bash
cp /opt/trusttunnel/trusttunnel.service.template /etc/systemd/system/trusttunnel.service
sudo systemctl daemon-reload
sudo systemctl enable --now trusttunnel
```

### 2. Установка клиента

Скачайте клиент для архитектуры вашего роутера:

```bash
curl -fsSL https://raw.githubusercontent.com/TrustTunnel/TrustTunnelClient/refs/heads/master/scripts/install.sh | sh -s -
```

Поддерживаемые архитектуры: x86_64, aarch64, armv7, mips, mipsel.

Для Keenetic обычно нужна архитектура **mipsel** или **aarch64** (зависит от модели).

После скачивания скопируйте бинарник на роутер в `/opt/trusttunnel_client/`.

Подробная документация: https://github.com/TrustTunnel/TrustTunnel

---

## Быстрая установка на Keenetic

Выполните одну команду на роутере:

```bash
curl -fsSL https://raw.githubusercontent.com/artemevsevev/TrustTunnel-Keenetic/main/install.sh | sh
```

или с wget:

```bash
wget -qO- https://raw.githubusercontent.com/artemevsevev/TrustTunnel-Keenetic/main/install.sh | sh
```

После установки скриптов необходимо:
1. Разместить бинарник `trusttunnel_client` в `/opt/trusttunnel_client/`
2. Создать конфигурацию `/opt/trusttunnel_client/trusttunnel_client.toml`
3. Сделать бинарник исполняемым: `chmod +x /opt/trusttunnel_client/trusttunnel_client`
4. Запустить сервис: `/opt/etc/init.d/S99trusttunnel start`

## Структура файлов

```
/opt/
├── etc/
│   ├── init.d/
│   │   └── S99trusttunnel          # Основной init-скрипт
│   └── ndm/
│       └── wan.d/
│           └── 010-trusttunnel.sh  # Хук при поднятии WAN
├── var/
│   ├── run/
│   │   ├── trusttunnel.pid         # PID клиента
│   │   └── trusttunnel_watchdog.pid # PID watchdog
│   └── log/
│       └── trusttunnel.log         # Лог работы
└── trusttunnel_client/
    ├── trusttunnel_client          # Бинарник клиента
    └── trusttunnel_client.toml     # Конфигурация
```

## Ручная установка

Если вы предпочитаете ручную установку вместо скрипта:

```bash
# Создаём директории
mkdir -p /opt/etc/init.d
mkdir -p /opt/etc/ndm/wan.d
mkdir -p /opt/var/run
mkdir -p /opt/var/log

# Init-скрипт
curl -fsSL https://raw.githubusercontent.com/artemevsevev/TrustTunnel-Keenetic/main/S99trusttunnel -o /opt/etc/init.d/S99trusttunnel
chmod +x /opt/etc/init.d/S99trusttunnel

# WAN-хук
curl -fsSL https://raw.githubusercontent.com/artemevsevev/TrustTunnel-Keenetic/main/010-trusttunnel.sh -o /opt/etc/ndm/wan.d/010-trusttunnel.sh
chmod +x /opt/etc/ndm/wan.d/010-trusttunnel.sh

# Убедитесь, что клиент исполняемый
chmod +x /opt/trusttunnel_client/trusttunnel_client
```

## Использование

### Управление сервисом

```bash
# Запуск (клиент + watchdog)
/opt/etc/init.d/S99trusttunnel start

# Остановка (клиент + watchdog)
/opt/etc/init.d/S99trusttunnel stop

# Полный перезапуск
/opt/etc/init.d/S99trusttunnel restart

# Мягкий перезапуск (только клиент, watchdog перезапустит его)
/opt/etc/init.d/S99trusttunnel reload

# Проверка статуса
/opt/etc/init.d/S99trusttunnel status
```

### Просмотр логов

```bash
# Текущий лог
cat /opt/var/log/trusttunnel.log

# В реальном времени
tail -f /opt/var/log/trusttunnel.log
```

## Как это работает

### Автозапуск при загрузке
- Entware автоматически запускает все скрипты `S*` в `/opt/etc/init.d/` при старте
- Скрипт `S99trusttunnel` запускается последним (99 = высокий приоритет)

### Watchdog (перезапуск при падении)
- После запуска клиента стартует фоновый процесс watchdog
- Каждые 10 секунд проверяет, жив ли клиент
- При падении автоматически перезапускает

### Переподключение WAN
- Keenetic вызывает скрипты из `/opt/etc/ndm/wan.d/` при поднятии WAN
- Скрипт `010-trusttunnel.sh` инициирует перезапуск клиента
- Watchdog подхватит и запустит клиент заново

### Защита от дублей
- PID-файл предотвращает запуск нескольких экземпляров
- Проверка через `pidof` как fallback

## Отключение автозапуска

```bash
# Временно (до следующего ребута)
/opt/etc/init.d/S99trusttunnel stop

# Постоянно
# Измените ENABLED=yes на ENABLED=no в скрипте
# или удалите/переименуйте скрипт:
mv /opt/etc/init.d/S99trusttunnel /opt/etc/init.d/_S99trusttunnel
```

## Troubleshooting

### Клиент не запускается
```bash
# Проверьте права
ls -la /opt/trusttunnel_client/

# Попробуйте запустить вручную
/opt/trusttunnel_client/trusttunnel_client -c /opt/trusttunnel_client/trusttunnel_client.toml

# Проверьте лог
cat /opt/var/log/trusttunnel.log
```

### Watchdog не работает
```bash
# Проверьте процессы
ps | grep trusttunnel

# Проверьте PID файлы
cat /opt/var/run/trusttunnel_watchdog.pid
```

### WAN-хук не срабатывает
```bash
# Проверьте права
ls -la /opt/etc/ndm/wan.d/

# Проверьте, что Keenetic поддерживает ndm хуки
# (требуется установленный пакет opt в прошивке)
```
