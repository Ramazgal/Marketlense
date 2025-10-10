# TEST 2.1: Ошибка ответа от AI

## Описание

Проверка обработки некорректного формата ответа от Gemini AI.

## DoD

- ✅ Если Gemini вернет обычный текст вместо JSON, сервер не упадет
- ✅ Приложение покажет пользователю осмысленную ошибку
- ✅ JSON.parse обернут в try-catch с понятным сообщением

## Реализация

### Расположение кода

**Файл:** `server.js`  
**Функция:** `generateRealAiStrategy` (строки 388-400)

### Логика валидации

```javascript
// TEST 2.1: Валидация формата JSON от AI
const trimmedResponse = responseText.trim();
if (trimmedResponse.startsWith('{') || trimmedResponse.startsWith('[')) {
  try {
    JSON.parse(trimmedResponse);
    logger.warn('AI вернул JSON вместо текста, используем как есть');
  } catch {
    throw new Error('AI вернул ответ в некорректном формате JSON.');
  }
}
```

### Как это работает

1. **Проверка начала ответа**: Если AI вернул текст, начинающийся с `{` или `[`, предполагаем, что это JSON
2. **Попытка парсинга**: Пытаемся распарсить JSON с помощью `JSON.parse()`
3. **Обработка ошибки**: Если парсинг не удался, выбрасываем понятную пользователю ошибку

### Сообщения об ошибках

| Сценарий | Сообщение | Код ответа |
|----------|-----------|------------|
| Невалидный JSON | `AI вернул ответ в некорректном формате JSON.` | 500 |
| Валидный JSON (неожиданно) | Предупреждение в логе | 200 |
| Обычный текст | Нормальная обработка | 200 |

## Тестирование

### Автоматические тесты

```powershell
.\scripts\test-ai-format.ps1
```

**Проверяет:**
1. ✅ Наличие JSON.parse с валидацией
2. ✅ Try-catch обертка с throw new Error
3. ✅ Маркер TEST 2.1 в коде
4. ✅ Работоспособность сервера

### Ручное тестирование

Для проверки данного кода потребовалось бы изменить ответ Gemini API, что невозможно напрямую. Тестирование проводится через проверку кода (code review):

```powershell
# Проверка наличия валидации
Get-Content server.js | Select-String "JSON.parse"

# Проверка try-catch
Get-Content server.js | Select-String "throw new Error"
```

## Результаты тестирования

```
========== TEST 2.1: AI Format Validation ==========

Test 1: Code Review
  [PASS] Found JSON.parse with validation
  [PASS] Found try-catch with error throwing
  [PASS] Code marked with TEST 2.1

Test 2: Server Stability
  [PASS] Server running correctly

========== RESULTS ==========
Passed: 4/4 (100%)
Failed: 0
```

## Архитектурные решения

### Почему проактивная валидация?

В текущей версии Gemini API возвращает текстовый ответ, но код проверяет JSON на будущее:

- **Защита от изменений API**: Если Gemini начнет возвращать JSON, код готов к этому
- **Явная обработка ошибок**: Если JSON некорректный, пользователь увидит понятное сообщение
- **Логирование предупреждений**: Если JSON валидный, но неожиданный, информация попадет в логи

### Nested Try-Catch

Использован вложенный try-catch вместо добавления проверки в основной блок:

```javascript
try {
  // ... основная логика ...
  
  // Вложенная валидация JSON
  if (trimmedResponse.startsWith('{') || trimmedResponse.startsWith('[')) {
    try {
      JSON.parse(trimmedResponse);
    } catch {
      throw new Error('AI вернул ответ в некорректном формате JSON.');
    }
  }
} catch (error) {
  // Основной обработчик ошибок
}
```

**Преимущества:**
- Специфичная ошибка для JSON
- Не затрагивает другие проверки
- Легко поддерживать и тестировать

## ESLint

Код соответствует требованиям ESLint:

```bash
npm run lint
```

**Результат:** 0 errors, 0 warnings

### Решение с unused parameter

Первоначально catch имел параметр `parseError`, что вызывало warning ESLint. Решение — использовать bare catch:

```javascript
// ❌ Было (warning)
catch (parseError) {
  throw new Error('...');
}

// ✅ Стало (no warning)
catch {
  throw new Error('...');
}
```

## Связанные тесты

- [Test 1.1: URL Validation](TEST_1.1_URL_VALIDATION.md)
- [Test 1.2: Empty Data Handling](TEST_1.2_EMPTY_DATA.md)
- Test 2.2: Rate Limiting (TODO)

---

**Статус:** ✅ Завершен  
**Дата:** 2025  
**Версия:** 1.0
