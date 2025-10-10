# MarketLens 🚀

> AI-powered маркетплейс-аналитика: анализ конкурентов, поиск лидеров ниши и мониторинг цен на Ozon, Wildberries, Яндекс Маркет

[![Node.js](https://img.shields.io/badge/Node.js-20.x-green.svg)](https://nodejs.org/)
[![Version](https://img.shields.io/badge/version-6.0.0-blue.svg)](https://github.com/yourname/marketlens)
[![Production Ready](https://img.shields.io/badge/production-ready-brightgreen.svg)](./PRODUCTION.md)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## 📋 Возможности

- **🔍 Анализ карточки товара** — глубокий разбор с конкурентным окружением
- **🎯 Поиск лидеров** — топ-3 товара по ключевому слову на трёх площадках
- **📊 Мониторинг** — отслеживание изменения цен, рейтинга и отзывов
- **💾 Персистентное хранение** — данные сохраняются после перезапуска
- **🤖 AI-стратегия** — персональные рекомендации от Google Gemini
- **🔐 Production Ready** — Rate Limiting, Helmet, SSL, PM2

---

## 🚀 Быстрый старт (Development)

### Требования
- **Node.js** 20.x или выше ([скачать](https://nodejs.org/))
- **npm** (входит в Node.js)
- **Gemini API ключ** ([получить здесь](https://aistudio.google.com/app/apikey))

### Установка

1. **Клонируйте репозиторий:**
   ```bash
   git clone https://github.com/ваш-логин/Marketlense.git
   cd Marketlense
   ```

2. **Установите зависимости:**
   ```bash
   npm install
   ```

3. **Настройте переменные окружения:**
   ```bash
   cp .env.example .env
   ```
   Откройте `.env` и добавьте ваш API-ключ:
   ```env
   GEMINI_API_KEY=ваш_ключ_здесь
   ```

4. **Запустите сервер:**
   ```bash
   npm start
   ```
   Сервер запустится на `http://localhost:3000`

5. **Откройте фронтенд:**
   - Откройте `index.html` в браузере
   - Или используйте Live Server в VS Code

---

## 🌐 Production Деплой

### 🚀 GitHub Pages (Фронтенд)

**Быстрая инструкция:** [GITHUB_SETUP.md](./GITHUB_SETUP.md)  
**Команды:** [GIT_COMMANDS.txt](./GIT_COMMANDS.txt)

**5 шагов:**
```powershell
# 1. Создай репозиторий на GitHub (Public)

# 2. Инициализируй Git локально
git init
git add .
git commit -m "Initial commit: MarketLens v6.0.0"
git branch -M main

# 3. Подключи GitHub (замени твой-username)
git remote add origin https://github.com/твой-username/marketlens.git

# 4. Загрузи код
git push -u origin main

# 5. Включи GitHub Pages
#    Settings → Pages → Branch: main → Folder: /docs → Save
```

**Результат:** Фронтенд доступен на `https://твой-username.github.io/marketlens/`

---

### 🖥️ Selectel VPS (Бэкенд)

**Полная инструкция:** [PRODUCTION.md](./PRODUCTION.md)  
**Детальный гайд:** [DEPLOYMENT.md](./DEPLOYMENT.md)  
**Автодеплой:** [START_HERE.md](./START_HERE.md)

**Краткая версия:**
```bash
# 1. На сервере (Ubuntu 22.04)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt install -y nodejs postgresql nginx certbot python3-certbot-nginx
sudo npm install -g pm2

# 2. Загрузите код и установите зависимости
npm install --production

# 3. Настройте .env из .env.production
# Добавьте: FRONTEND_URL=https://твой-username.github.io

# 4. Запустите через PM2
pm2 start ecosystem.config.js --env production
pm2 startup && pm2 save

# 5. Настройте Nginx + SSL
sudo certbot --nginx -d your-domain.com
```

### 📊 Production Features

- ✅ **Rate Limiting** — защита от DDoS (100 req/15 min)
- ✅ **Helmet.js** — HTTP security headers
- ✅ **SSL/HTTPS** — Let's Encrypt автоматически
- ✅ **PM2 Cluster** — использование всех CPU ядер
- ✅ **Health Check** — мониторинг состояния (`/health`)
- ✅ **Log Rotation** — автоматическая ротация логов
- ✅ **Auto Backup** — ежедневные бэкапы данных

---

## 📦 Скрипты

### Development
```bash
npm start              # Запуск в dev режиме
npm run lint           # Проверка кода ESLint
```

### Production (на сервере)
```bash
npm start              # Запуск в production
./scripts/deploy.sh    # Автоматический деплой обновлений
./scripts/backup.sh    # Создать бэкап
./scripts/restore.sh   # Восстановить из бэкапа
```

### PM2 (Production)
```bash
pm2 start ecosystem.config.js --env production  # Запуск
pm2 logs                                        # Логи
pm2 monit                                       # Мониторинг
pm2 restart marketlens-api                      # Перезапуск
pm2 reload marketlens-api                       # Reload без даунтайма
```

4. Проверьте статус:
   ```bash
   pm2 status
   pm2 logs marketlense
   ```

### Вариант 2: Docker

1. Соберите образ:
   ```bash
   docker build -t marketlense .
   ```

2. Запустите контейнер:
   ```bash
   docker run -d \
     --name marketlense \
     -p 3000:3000 \
     -e GEMINI_API_KEY=ваш_ключ \
     marketlense
   ```

3. Проверьте логи:
   ```bash
   docker logs -f marketlense
   ```

### Вариант 3: systemd (Linux)

Создайте файл `/etc/systemd/system/marketlense.service`:
```ini
[Unit]
Description=MarketLens Backend
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/path/to/Marketlense
Environment=NODE_ENV=production
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Активируйте сервис:
```bash
sudo systemctl enable marketlense
sudo systemctl start marketlense
sudo systemctl status marketlense
```

---

## 🧪 Тестирование

### ⚡ Быстрый тест (рекомендуется)
```bash
powershell -File scripts/test-quick.ps1
```
**Проверяет:** Health, Linting, Monitoring (6 тестов за ~5 секунд)  
**Результат:** ✅ 6/6 PASS (100%)

### Smoke-тест (автоматический)
```bash
powershell -File scripts/smoke-test.ps1
```
или
```bash
./scripts/smoke-test.sh
```

### Тесты робастности
```bash
# Тест 1.1: Валидация URL (битые ссылки) ✅ READY
# Документация: docs/TEST_1.1_URL_VALIDATION.md
# Запуск: powershell -File scripts/test-url-validation.ps1

# Тест 1.2: Обработка пустых данных ✅ READY
# Документация: docs/TEST_1.2_EMPTY_DATA.md
# Запуск: powershell -File scripts/test-empty-data.ps1

# Тест 2.1: Ошибка ответа от AI ✅ READY
# Документация: TEST_2.1_AI_FORMAT.md
# Запуск: powershell -File scripts/test-ai-format.ps1

# Тест 3.1: Нервный пользователь (блокировка кнопок) ✅ READY
# Документация: TEST_3.1_NERVOUS_USER.md
# Запуск: powershell -File scripts/test-nervous-user.ps1

# Тест 3.2: Медленный интернет (таймаут 15 секунд) ✅ READY
# Документация: TEST_3.2_SLOW_INTERNET.md
# Запуск: powershell -File scripts/test-slow-internet.ps1

# Тест 3.3: Мобильная адаптивность (ручной тест) ✅ READY
# Документация: TEST_3.3_MOBILE_RESPONSIVE.md
# Инструкция: Откройте Chrome DevTools → Device Mode → iPhone 12 Pro

# Инструкции по тестированию таймаутов (15 секунд)
powershell -File scripts/test-timeout-simple.ps1
```

### Тесты функционала
```bash
# Тест 4.1: Мониторинг цен (ручной тест) ✅ READY
# Документация: TEST_4.1_MONITORING_TEST.md
# Инструкция: Добавить товар → вызвать POST /monitoring/test-change → проверить обновления

# Тест 4.2: Экспертная оценка AI-советов (ручной тест) ✅ READY
# Документация: TEST_4.2_AI_EXPERT_EVALUATION.md
# Инструкция: 3 сценария с peer review от второго AI (ChatGPT/Copilot)

# Тест 4.3: Целостность данных (End-to-End) ✅ READY
# Документация: TEST_4.3_DATA_INTEGRITY.md
# Запуск: powershell -File scripts/test-data-integrity.ps1
# Проверка: логи в терминале сервера (2 checkpoint'а)

# Тест 4.4: Релевантность поиска (ручной тест) ✅ READY
# Документация: TEST_4.4_SEARCH_RELEVANCE.md
# Запуск: powershell -File scripts/test-search-manual.ps1
# DoD: По запросу "рубашка мужская белая" в выдаче нет футболок

# Тест 4.5: "Живой" Мониторинг (ручной тест) ✅ READY
# Документация: TEST_4.5_UNAVAILABLE_MONITORING.md
# Инструкция: Добавить несуществующий товар → Проверить обновления → Плашка "Товар недоступен"

# Тест 5.1: Долговременная Память (ручной тест) ✅ READY
# Документация: TEST_5.1_PERSISTENT_STORAGE.md
# DoD: Добавить 2-3 товара → Перезапустить сервер (Ctrl+C, npm start) → Товары остались
```

### 📊 Подробные отчёты
- **[Полный отчёт о тестировании](docs/TEST_RESULTS.md)** - результаты всех тестов
- **[Тест 1.1: URL Validation](docs/TEST_1.1_URL_VALIDATION.md)** - проверка битых ссылок
- **[Тест 1.2: Empty Data](docs/TEST_1.2_EMPTY_DATA.md)** - обработка пустых данных
- **[Тест 2.1: AI Format](TEST_2.1_AI_FORMAT.md)** - валидация формата ответа AI
- **[Тест 3.1: Nervous User](TEST_3.1_NERVOUS_USER.md)** - блокировка кнопок при запросах
- **[Тест 3.2: Slow Internet](TEST_3.2_SLOW_INTERNET.md)** - таймаут 15 секунд для запросов
- **[Тест 3.3: Mobile Responsive](TEST_3.3_MOBILE_RESPONSIVE.md)** - мобильная адаптивность (iPhone 12 Pro)
- **[Тест 4.1: Monitoring Test](TEST_4.1_MONITORING_TEST.md)** - ручной тест мониторинга цен
- **[Тест 4.2: AI Expert Evaluation](TEST_4.2_AI_EXPERT_EVALUATION.md)** - ручная оценка качества AI-советов (3 сценария + peer review)
- **[Тест 4.3: Data Integrity](TEST_4.3_DATA_INTEGRITY.md)** - E2E тест целостности данных (парсер → AI, 2 checkpoint'а)
- **[Тест 4.4: Search Relevance](TEST_4.4_SEARCH_RELEVANCE.md)** - ручной тест релевантности поиска (DoD: нет футболок по запросу "рубашка")
- **[Тест 4.5: Unavailable Monitoring](TEST_4.5_UNAVAILABLE_MONITORING.md)** - ручной тест обработки недоступных товаров (DoD: плашка "Товар недоступен")
- **[Тест 5.1: Persistent Storage](TEST_5.1_PERSISTENT_STORAGE.md)** - сохранение данных мониторинга в файл (DoD: товары остаются после перезапуска сервера)

### Линтинг кода
```bash
npm run lint
```

### Ручная проверка эндпоинтов
```bash
# Health check
curl http://localhost:3000/health

# Анализ товара
curl "http://localhost:3000/analyze?url=https://www.ozon.ru/product/example&marketplace=ozon"

# Поиск
curl "http://localhost:3000/search?query=умная колонка&limit=5"
```

### Проверка таймаутов в браузере
1. Откройте `index.html` в браузере
2. Откройте DevTools (F12) → Network → Throttling → **Offline**
3. Нажмите кнопку "Анализ" или "Поиск"
4. **Ожидаемое поведение:** Через 15 секунд появится ошибка:
   > *"Сервер слишком долго не отвечает. Попробуйте позже."*

Подробнее: [docs/TIMEOUT_UPGRADE.md](docs/TIMEOUT_UPGRADE.md)

---

## 🔧 Конфигурация

### Переменные окружения (.env)

| Параметр | По умолчанию | Описание |
|----------|--------------|----------|
| `GEMINI_API_KEY` | — | **Обязательный.** API-ключ Google Gemini |
| `GEMINI_MODEL` | `gemini-1.5-flash` | Модель для генерации |
| `PORT` | `3000` | Порт сервера |
| `LOG_LEVEL` | `info` | Уровень логирования (trace, debug, info, warn, error) |
| `REQUEST_TIMEOUT_MS` | `10000` | Таймаут HTTP-запросов (мс) |
| `NODE_ENV` | `development` | Окружение (production / development) |

---

## 📚 API Документация

### `GET /health`
Проверка доступности сервера.

**Ответ:**
```json
{
  "status": "ok",
  "timestamp": "2025-10-01T12:00:00.000Z"
}
```

### `GET /analyze`
Анализ карточки товара.

**Параметры:**
- `url` (string, обязательный) — ссылка на товар
- `marketplace` (enum: ozon, wildberries, yandex_market, обязательный)
- `withCompetitors` (boolean, по умолчанию: true)

**Пример:**
```bash
GET /analyze?url=https://www.ozon.ru/product/123&marketplace=ozon&withCompetitors=true
```

### `GET /search`
Поиск лидеров по ключевому слову.

**Параметры:**
- `query` (string, 2-80 символов, обязательный)
- `marketplace` (enum, необязательный) — если не указан, ищет по всем площадкам
- `limit` (number, 1-20, по умолчанию: 5)

### `POST /monitoring/add`
Добавление товара в мониторинг.

**Body:**
```json
{
  "productUrl": "https://www.wildberries.ru/catalog/123",
  "marketplace": "wildberries",
  "notes": "главный конкурент"
}
```

### `POST /strategize`
Генерация AI-стратегии.

**Body:**
```json
{
  "userEvidence": ["Наш товар: цена 2990₽", "Рейтинг 4.8"],
  "competitorsEvidence": ["Конкурент A: 3500₽, рейтинг 4.5"],
  "tone": "analytical",
  "focus": ["pricing", "marketing"]
}
```

---

## ⚠️ Возможные проблемы

### Сервер не запускается

**Проблема:** `Error: GEMINI_API_KEY не найден`  
**Решение:** Создайте `.env` на основе `.env.sample` и добавьте валидный ключ.

**Проблема:** `EADDRINUSE: порт 3000 уже занят`  
**Решение:** Измените порт в `.env` (`PORT=3001`) или освободите порт:
```bash
# Linux/Mac
lsof -ti:3000 | xargs kill -9

# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F
```

### Фронтенд не может подключиться к бэкенду

**Проблема:** `Failed to fetch`  
**Решение:**  
1. Убедитесь, что сервер запущен: `curl http://localhost:3000/health`
2. Проверьте, что фронтенд открыт через HTTP-сервер (не `file://`)
3. Если сервер на другом хосте, обновите `API_BASE_URL` в `index.html`

### Парсеры не работают

**Проблема:** Маркетплейсы изменили структуру HTML  
**Решение:** Обновите селекторы в функциях `parseOzon`, `parseWildberries`, `parseYandexMarket` в `server.js`

---

## 🛠️ Разработка

### Структура проекта
```
Marketlense/
├── server.js              # Express API + парсеры
├── index.html             # Фронтенд UI
├── manifest.json          # PWA манифест
├── package.json           # Зависимости и скрипты
├── .env                   # Переменные окружения (не в Git)
├── .env.sample            # Шаблон переменных
├── .gitignore             # Игнор для Git
├── ecosystem.config.js    # PM2 конфигурация
├── Dockerfile             # Docker-образ
├── scripts/
│   └── smoke-test.ps1     # Автотест для Windows
└── README.md              # Документация
```

### Добавление нового маркетплейса

1. Создайте парсер-функцию в `server.js`:
   ```javascript
   async function parseNewMarket(productUrl) {
     // ... логика парсинга
   }
   ```

2. Добавьте в `parserMap`:
   ```javascript
   const parserMap = {
     ozon: parseOzon,
     wildberries: parseWildberries,
     yandex_market: parseYandexMarket,
     new_market: parseNewMarket
   };
   ```

3. Обновите схему валидации:
   ```javascript
   const marketplaceSchema = z.enum(['ozon', 'wildberries', 'yandex_market', 'new_market']);
   ```

---

## 🤝 Вклад в проект

1. Форкните репозиторий
2. Создайте ветку для фичи (`git checkout -b feature/amazing`)
3. Закоммитьте изменения (`git commit -m 'Add amazing feature'`)
4. Запушьте ветку (`git push origin feature/amazing`)
5. Откройте Pull Request

---

## 📄 Лицензия

MIT License — свободно используйте в коммерческих и некоммерческих целях.

---

## 🔗 Ссылки

- [Google Gemini API](https://aistudio.google.com/app/apikey)
- [PM2 Process Manager](https://pm2.keymetrics.io/)
- [Docker Documentation](https://docs.docker.com/)
- [Node.js Documentation](https://nodejs.org/docs/)

---

**Сделано с ❤️ для селлеров маркетплейсов**
