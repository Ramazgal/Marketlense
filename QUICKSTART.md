# 🚀 Быстрый старт MarketLens v6.1.0 (Amvera GPT Edition)

## ✅ Статус миграции: ЗАВЕРШЕНО

Все 4 шага миграции на Amvera GPT-4.1 успешно выполнены!

---

## 📋 Что сделано

- ✅ **Шаг 1:** AMVERA_API_KEY настроен в .env
- ✅ **Шаг 2:** @google/generative-ai удалён
- ✅ **Шаг 3:** Все функции переписаны для Amvera API
- ✅ **Шаг 4:** Сервер запускается с "🚀 Amvera GPT Сервер MarketLens v6.1"

---

## 🎯 Как запустить

### 1. Production сервер
```bash
npm start
```

Вы увидите:
```
🚀 Amvera GPT Сервер MarketLens v6.1 запущен
    version: "6.1.0"
    aiProvider: "Amvera GPT-4.1"
    port: 3000
```

### 2. Тестовый сервер (для отладки)
```bash
node test-server.js
```

Откройте: http://localhost:3000/test-ai.html

### 3. Health Check
```bash
curl http://localhost:3000/health
```

---

## 🧪 Как протестировать AI

### Вариант 1: Web-интерфейс (РЕКОМЕНДУЕТСЯ)
1. Запустите: `node test-server.js`
2. Откройте в браузере: http://localhost:3000/test-ai.html
3. Нажмите кнопку "🧠 Запросить AI-стратегию от GPT-4.1"
4. Посмотрите результат

### Вариант 2: curl (если работает)
```bash
curl -X POST http://localhost:3000/test-strategy \
  -H "Content-Type: application/json" \
  -d @test-request.json
```

### Вариант 3: Postman / Thunder Client
Endpoint: `POST http://localhost:3000/strategize`

Body (JSON):
```json
{
  "userEvidence": ["Наш товар: 2990₽, рейтинг 4.8"],
  "competitorsEvidence": ["Конкурент: 3500₽"],
  "tone": "analytical",
  "focus": ["pricing", "marketing"]
}
```

---

## 📊 Что изменилось

| Параметр | Было | Стало |
|----------|------|-------|
| AI Provider | Google Gemini | **Amvera GPT-4.1** |
| SDK | @google/generative-ai | **Прямой HTTP (axios)** |
| API Key | GEMINI_API_KEY | **AMVERA_API_KEY** |
| Версия | 6.0.0 | **6.1.0** |
| Response | Текст | **JSON Structure** |

---

## 📝 Важные файлы

### Основные
- `server.js` - Production сервер с Amvera API
- `package.json` - Версия 6.1.0
- `.env` - AMVERA_API_KEY (НЕ коммитить!)

### Тестовые
- `test-server.js` - Упрощённый сервер
- `test-ai.html` - Web-интерфейс тестирования
- `test-request.json` - Тестовые данные

### Документация
- `AMVERA_MIGRATION_COMPLETE.md` - Полное резюме миграции
- `STEP4_TEST_DRIVE_DONE.md` - Детали Шага 4
- `STEP3_BRAIN_TRANSPLANT_DONE.md` - Детали Шага 3
- `STEP2_CLEANUP_DONE.md` - Детали Шага 2
- `AMVERA_STEP1_DONE.md` - Детали Шага 1

---

## 🔧 Технические характеристики

**Amvera GPT-4.1 API:**
- Endpoint: `https://llm.api.amvera.ru/v1/chat/completions`
- Model: `gpt-4.1`
- Auth: `X-Auth-Token: Bearer ${AMVERA_API_KEY}`
- Format: JSON Object
- Timeout: 30 seconds

**Server:**
- Port: 3000
- Host: 0.0.0.0
- Rate Limiting: Enabled
- Security: Helmet enabled

---

## ❓ FAQ

### Q: Сервер не запускается?
A: Проверьте, что `AMVERA_API_KEY` есть в `.env` файле.

### Q: Порт 3000 занят?
A: Остановите процесс:
```bash
$proc = netstat -ano | findstr :3000 | ForEach-Object { $_ -split '\s+' | Select-Object -Last 1 } | Select-Object -First 1; if ($proc) { taskkill /F /PID $proc }
```

### Q: Где посмотреть логи?
A: Запустите сервер и смотрите вывод в терминале.

### Q: Как протестировать AI без curl?
A: Используйте `test-ai.html` - откройте в браузере.

### Q: Работает ли старый код с Gemini?
A: Нет, всё мигрировано на Amvera API. Gemini SDK удалён.

---

## 🎉 Готово к работе!

MarketLens v6.1.0 с Amvera GPT-4.1 готов к тестированию и production использованию.

**Следующий шаг:** Откройте http://localhost:3000/test-ai.html и протестируйте AI! 🚀
