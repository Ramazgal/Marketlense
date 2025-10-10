# ✅ ШАГ 2: ОЧИСТКА «ИНСТРУМЕНТОВ» - АНАЛИЗ

**Дата:** 10 октября 2025 г.  
**Шаг:** 2 - Очистка неиспользуемых библиотек  
**Статус:** ⚠️ **В ПРОЦЕССЕ** (требуется дополнительная работа)

---

## 🔍 Анализ package.json

### Найденные библиотеки для удаления:

1. **`@google/generative-ai`** ✅ Найдена
   - Версия: `^0.14.1`
   - Статус: Установлена в `dependencies`

2. **`openai`** ❌ Не найдена
   - Статус: Не установлена (не требуется удаление)

---

## 🗑️ Команда для удаления

```bash
npm uninstall @google/generative-ai
```

**Примечание:** Библиотека `openai` не установлена, поэтому удалять её не нужно.

---

## ✅ Выполнено

### 1. **npm uninstall выполнен** ✅

```bash
npm uninstall @google/generative-ai
```

**Результат:**
```
removed 1 package, and audited 476 packages in 3s
```

**Статус:** ✅ Команда выполнена без ошибок

---

### 2. **package.json обновлён** ✅

**До:**
```json
{
  "dependencies": {
    "@google/generative-ai": "^0.14.1",
    "axios": "^1.7.2",
    ...
  }
}
```

**После:**
```json
{
  "dependencies": {
    "axios": "^1.7.2",
    "cheerio": "^1.0.0-rc.12",
    "cors": "^2.8.5",
    ...
  }
}
```

**Результат:** ✅ `@google/generative-ai` удалён из dependencies

---

## ⚠️ ПРОБЛЕМА: Код ещё использует удалённую библиотеку!

### Найдены использования в server.js:

**Строка 13:**
```javascript
const { GoogleGenerativeAI } = require('@google/generative-ai');
```

**Строка 38:**
```javascript
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const aiModel = genAI.getGenerativeModel({ model: GEMINI_MODEL });
```

**Использование aiModel:**
- **Строка 479:** `const result = await aiModel.generateContent(prompt);`
- **Строка 542:** `await aiModel.generateContent('test');`

---

## 🔧 Что нужно исправить

### Проблема:
Библиотека `@google/generative-ai` удалена из `package.json`, но код в `server.js` всё ещё пытается её использовать!

### Решение:
Заменить использование SDK на **прямые HTTP-запросы к Gemini REST API**.

---

## 📋 План исправления

### Шаг 2.1: Удалить импорты

**Удалить строку 13:**
```javascript
// УДАЛИТЬ:
const { GoogleGenerativeAI } = require('@google/generative-ai');
```

### Шаг 2.2: Удалить инициализацию

**Удалить строки 38-39:**
```javascript
// УДАЛИТЬ:
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const aiModel = genAI.getGenerativeModel({ model: GEMINI_MODEL });
```

### Шаг 2.3: Создать функцию для HTTP-запросов

**Добавить новую функцию:**
```javascript
async function callGeminiAPI(prompt) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${process.env.GEMINI_API_KEY}`;
  
  const response = await axios.post(url, {
    contents: [{
      parts: [{ text: prompt }]
    }]
  }, {
    timeout: REQUEST_TIMEOUT_MS
  });
  
  return response.data.candidates[0].content.parts[0].text;
}
```

### Шаг 2.4: Заменить использование aiModel

**В строке 479:**
```javascript
// БЫЛО:
const result = await aiModel.generateContent(prompt);
const text = result.response.text();

// СТАНЕТ:
const text = await callGeminiAPI(prompt);
```

**В строке 542:**
```javascript
// БЫЛО:
await aiModel.generateContent('test');

// СТАНЕТ:
await callGeminiAPI('test');
```

---

## ✅ DoD Статус

**Требование:** Команда выполнена без ошибок.

**Текущий статус:**
- ✅ Команда `npm uninstall` выполнена без ошибок
- ⚠️ **НО:** Код ещё не обновлён!

**Полный DoD:**
- [x] `npm uninstall @google/generative-ai` выполнен
- [x] `package.json` обновлён
- [ ] Импорты удалены из `server.js`
- [ ] Код переписан на HTTP-запросы
- [ ] Приложение запускается без ошибок
- [ ] AI функционал работает

---

## 🚀 Следующие действия

**Вариант 1: Продолжить очистку (рекомендуется)**
1. Удалить импорты из `server.js`
2. Создать функцию `callGeminiAPI()`
3. Заменить `aiModel.generateContent()` на `callGeminiAPI()`
4. Протестировать работу AI

**Вариант 2: Откатить изменения**
Если SDK нужен, вернуть библиотеку:
```bash
npm install @google/generative-ai@^0.14.1
```

---

## 📊 Итоги шага 2

**Выполнено:**
- ✅ Библиотека удалена из `package.json`
- ✅ `npm uninstall` выполнен без ошибок

**Осталось:**
- ⚠️ Обновить код в `server.js`
- ⚠️ Протестировать работу AI

**Рекомендация:** Продолжить с обновлением кода или откатить изменения, если SDK всё-таки нужен.

---

**Создано:** GitHub Copilot  
**Дата:** 10 октября 2025 г.  
**Проект:** MarketLens v6.0.0  
**Статус:** npm uninstall выполнен, требуется обновление кода
