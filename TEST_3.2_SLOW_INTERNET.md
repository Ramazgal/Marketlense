# TEST 3.2: Медленный интернет

## Описание

Защита от "зависших" запросов: автоматическое прерывание fetch-запросов через 15 секунд с понятным сообщением об ошибке.

## DoD

- ✅ Все fetch-запросы имеют таймаут 15 секунд
- ✅ При превышении таймаута запрос автоматически прерывается (AbortController)
- ✅ Пользователь видит сообщение: "Сервер слишком долго не отвечает. Попробуйте позже."

## Реализация

### Расположение кода

**Файл:** `index.html`  
**Секция:** JavaScript fetch-запросы

### Паттерн реализации таймаута

Для каждого fetch-запроса используется единый паттерн:

```javascript
// TEST 3.2: Таймаут 15 секунд
const abortController = new AbortController();
const timeoutId = setTimeout(() => abortController.abort(), 15000);

try {
    const response = await fetch(url, {
        // ... другие параметры ...
        signal: abortController.signal  // 🔑 Связываем с AbortController
    });
    clearTimeout(timeoutId);  // ✅ Отменяем таймаут при успехе
    
    // ... обработка ответа ...
} catch (fetchError) {
    clearTimeout(timeoutId);  // ✅ Отменяем таймаут при ошибке
    if (fetchError.name === 'AbortError') {
        throw new Error('Сервер слишком долго не отвечает. Попробуйте позже.');
    }
    throw fetchError;
}
```

### Детали реализации

#### 1. Анализ товара (`/analyze`)

**Строки:** 307-344

```javascript
// TEST 3.2: Таймаут 15 секунд
const abortController = new AbortController();
const timeoutId = setTimeout(() => abortController.abort(), 15000);

try {
    const response = await fetch(`/analyze?${params.toString()}`, {
        signal: abortController.signal
    });
    clearTimeout(timeoutId);
    const data = await response.json().catch(() => ({}));
    
    if (!response.ok) {
        const issue = data?.error || response.statusText || 'Неизвестная ошибка';
        throw new Error(issue);
    }
    
    // ... обработка результата ...
} catch (fetchError) {
    clearTimeout(timeoutId);
    if (fetchError.name === 'AbortError') {
        throw new Error('Сервер слишком долго не отвечает. Попробуйте позже.');
    }
    throw fetchError;
}
```

#### 2. Поиск лидеров (`/search`)

**Строки:** 442-492

```javascript
// TEST 3.2: Таймаут 15 секунд
const abortController = new AbortController();
const timeoutId = setTimeout(() => abortController.abort(), 15000);

try {
    const response = await fetch(url.toString(), {
        signal: abortController.signal
    });
    clearTimeout(timeoutId);
    // ... обработка ...
} catch (fetchError) {
    clearTimeout(timeoutId);
    if (fetchError.name === 'AbortError') {
        throw new Error('Сервер слишком долго не отвечает. Попробуйте позже.');
    }
    throw fetchError;
}
```

#### 3. Добавление в мониторинг (`/monitoring/add`)

**Строки:** 536-602

```javascript
// TEST 3.2: Таймаут 15 секунд
const abortController = new AbortController();
const timeoutId = setTimeout(() => abortController.abort(), 15000);

try {
    const response = await fetch('/monitoring/add', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            productUrl,
            marketplace,
            notes: notes || undefined
        }),
        signal: abortController.signal
    });
    clearTimeout(timeoutId);
    // ... обработка ...
} catch (fetchError) {
    clearTimeout(timeoutId);
    if (fetchError.name === 'AbortError') {
        throw new Error('Сервер слишком долго не отвечает. Попробуйте позже.');
    }
    throw fetchError;
}
```

#### 4. Проверка обновлений (`/monitoring/check-updates`)

**Строки:** 627-691 (добавлено в рамках Test 3.2)**

```javascript
// TEST 3.2: Таймаут 15 секунд
const abortController = new AbortController();
const timeoutId = setTimeout(() => abortController.abort(), 15000);

try {
    const response = await fetch('/monitoring/check-updates', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: abortController.signal
    });
    clearTimeout(timeoutId);
    // ... обработка ...
} catch (fetchError) {
    clearTimeout(timeoutId);
    if (fetchError.name === 'AbortError') {
        throw new Error('Сервер слишком долго не отвечает. Попробуйте позже.');
    }
    throw fetchError;
}
```

## Как это работает

### AbortController API

```javascript
const controller = new AbortController();
const signal = controller.signal;

// Прерывание запроса
controller.abort();

// Проверка в fetch
fetch(url, { signal });
```

### Механизм таймаута

1. **Создание контроллера:** `new AbortController()`
2. **Установка таймера:** `setTimeout(() => controller.abort(), 15000)`
3. **Привязка к fetch:** `fetch(url, { signal: controller.signal })`
4. **Обработка прерывания:** `catch (error) { if (error.name === 'AbortError') ... }`
5. **Очистка таймера:** `clearTimeout(timeoutId)` при успехе или ошибке

### Почему 15 секунд?

- ⏱️ Достаточно для медленных сетей (3G, 4G в плохих условиях)
- 👤 Не слишком долго для пользователя (UX best practice: < 20s)
- 🔄 Даёт время на тяжёлые операции (парсинг, AI-генерация)
- 📱 Соответствует стандартам мобильных приложений

## Тестирование

### Автоматические тесты

```powershell
.\scripts\test-slow-internet.ps1
```

**Проверяет:**
1. ✅ 4 AbortController instances
2. ✅ 4 таймаута по 15 секунд
3. ✅ 4 обработчика AbortError
4. ✅ Наличие timeout error handling
5. ✅ 4 fetch с параметром `signal`
6. ✅ 8+ вызовов `clearTimeout`
7. ✅ Работоспособность сервера

### Ручное тестирование

#### Вариант 1: Network Throttling (рекомендуется)

1. **Открыть `index.html` в браузере**
2. **Открыть DevTools (F12) → Network tab**
3. **Throttling → Offline** (или Custom → 0 kb/s)
4. **Действие:** Нажать любую кнопку (Анализ, Поиск, Мониторинг)
5. **Ожидаемое поведение:**
   - Через 15 секунд запрос автоматически прерывается
   - Появляется сообщение: *"Ошибка: Сервер слишком долго не отвечает. Попробуйте позже."*
   - Кнопка разблокируется (см. Test 3.1)

#### Вариант 2: Delay на сервере

**Временно измените `server.js`:**

```javascript
// В начале любого эндпоинта (например, /analyze)
await new Promise(resolve => setTimeout(resolve, 20000)); // 20 секунд
```

**Ожидаемое поведение:** Через 15 секунд клиент покажет ошибку таймаута, несмотря на то, что сервер ещё обрабатывает запрос.

#### Вариант 3: Отключение сервера

1. Остановить сервер: `Ctrl+C` в терминале с `npm start`
2. Попробовать отправить запрос с фронтенда
3. **Ожидаемое поведение:** Мгновенная ошибка (не таймаут, а network error)

**Примечание:** Этот вариант тестирует другой сценарий (сервер недоступен), не таймаут.

### Проверка в DevTools Console

```javascript
// Открыть Console в DevTools и выполнить:
const controller = new AbortController();
setTimeout(() => controller.abort(), 5000); // 5 секунд

fetch('http://localhost:3000/analyze?url=https://ozon.ru&marketplace=ozon', {
    signal: controller.signal
})
.then(r => r.json())
.then(d => console.log('Success:', d))
.catch(e => console.log('Error:', e.name, e.message));

// Ожидаемый результат через 5 секунд:
// Error: AbortError The user aborted a request.
```

## Результаты тестирования

```
========== TEST 3.2: Slow Internet ==========

Test 1: Code Review - Timeout Implementation
  Found 4 fetch requests
  [PASS] Found 4 AbortController instances (expected 4+)
  [PASS] Found 4 15-second timeouts (expected 4+)
  [PASS] Found 4 AbortError handlers (expected 4+)
  [PASS] Found timeout error handling (AbortError)
  [PASS] Found 4 fetch calls with signal parameter (expected 4+)
  [PASS] Found 8 clearTimeout calls (expected 4+)

Test 2: Server Stability
  [PASS] Server running correctly

========== RESULTS ==========
Passed: 7/7 (100%)
Failed: 0
```

## Архитектурные решения

### Почему вложенный try-catch?

```javascript
try {
    // Таймаут контроллер
    const abortController = new AbortController();
    const timeoutId = setTimeout(() => abortController.abort(), 15000);
    
    try {
        // Fetch с signal
        const response = await fetch(url, { signal: abortController.signal });
        clearTimeout(timeoutId);
        // ... обработка ...
    } catch (fetchError) {
        clearTimeout(timeoutId);
        if (fetchError.name === 'AbortError') {
            throw new Error('Сервер слишком долго не отвечает. Попробуйте позже.');
        }
        throw fetchError;
    }
} catch (error) {
    // Основной обработчик (показывает ошибку пользователю)
}
```

**Преимущества:**
- ✅ `clearTimeout` вызывается в любом случае (успех/ошибка)
- ✅ Специфичная ошибка для таймаута
- ✅ Другие ошибки (network, server) обрабатываются отдельно
- ✅ Легко читать и поддерживать

### Альтернативы (не использованы)

#### ❌ Глобальный таймаут для fetch

```javascript
// НЕ РАБОТАЕТ: fetch не имеет встроенного timeout
fetch(url, { timeout: 15000 }); // ❌ Нет такого параметра
```

#### ❌ Promise.race

```javascript
Promise.race([
    fetch(url),
    new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Timeout')), 15000)
    )
]);
```

**Проблема:** Fetch продолжает выполняться в фоне, расходуя ресурсы.

#### ✅ AbortController (выбранный вариант)

**Почему лучше:**
- Отменяет сам запрос (не только Promise)
- Браузер закрывает соединение
- Экономит ресурсы клиента и сервера
- Стандартный API (поддерживается всеми современными браузерами)

## Интеграция с другими тестами

### Test 3.1 (Нервный пользователь)

```javascript
try {
    // TEST 3.2: Таймаут
    const abortController = new AbortController();
    const timeoutId = setTimeout(() => abortController.abort(), 15000);
    
    try {
        const response = await fetch(url, { signal: abortController.signal });
        clearTimeout(timeoutId);
        // ...
    } catch (fetchError) {
        clearTimeout(timeoutId);
        if (fetchError.name === 'AbortError') {
            throw new Error('Сервер слишком долго не отвечает. Попробуйте позже.');
        }
        throw fetchError;
    }
} catch (error) {
    // Показываем ошибку пользователю
} finally {
    // TEST 3.1: Разблокировка кнопки
    if (button) button.disabled = false;
}
```

**Взаимодействие:**
- Таймаут прерывает запрос → ошибка передаётся в catch → кнопка разблокируется в finally

### Test 1.1 (URL Validation)

Таймаут работает **после** валидации URL:

```javascript
// TEST 1.1: Валидация
if (!productUrl) {
    // Ранний выход (без запроса)
    return;
}

// TEST 3.2: Таймаут (только если URL валиден)
const abortController = new AbortController();
// ...
```

## Browser Support

| Browser | AbortController | setTimeout | fetch |
|---------|----------------|------------|-------|
| Chrome 66+ | ✅ | ✅ | ✅ |
| Firefox 57+ | ✅ | ✅ | ✅ |
| Safari 12.1+ | ✅ | ✅ | ✅ |
| Edge 16+ | ✅ | ✅ | ✅ |

**Поддержка:** 97%+ пользователей (Can I Use, 2025)

## Edge Cases

### 1. Запрос завершился ровно за 15 секунд

```javascript
setTimeout(() => controller.abort(), 15000);
```

**Поведение:** Race condition между `clearTimeout` и `abort()`. В большинстве случаев запрос успеет завершиться, так как `clearTimeout` вызывается сразу после получения ответа.

### 2. Множественные вызовы abort()

```javascript
controller.abort();
controller.abort(); // Безопасно, ничего не происходит
```

**Поведение:** Повторные вызовы `abort()` игнорируются.

### 3. clearTimeout с уже сработавшим таймером

```javascript
const id = setTimeout(() => {}, 100);
await delay(200);
clearTimeout(id); // Безопасно, даже если таймер уже сработал
```

**Поведение:** `clearTimeout` безопасен в любом случае.

## Performance

### Memory Leaks?

**Нет.** AbortController и setTimeout автоматически очищаются:
- `clearTimeout` освобождает таймер
- `AbortController` собирается garbage collector после выхода из области видимости
- Браузер закрывает соединение при `abort()`

### CPU Usage?

**Минимальный.** `setTimeout` — легковесная операция (< 1ms overhead).

## Связанные тесты

- [Test 1.1: URL Validation](docs/TEST_1.1_URL_VALIDATION.md) — валидация перед запросом
- [Test 1.2: Empty Data Handling](docs/TEST_1.2_EMPTY_DATA.md) — обработка пустых ответов
- [Test 2.1: AI Format Validation](TEST_2.1_AI_FORMAT.md) — валидация JSON от AI
- [Test 3.1: Nervous User](TEST_3.1_NERVOUS_USER.md) — блокировка кнопок (finally)

---

**Статус:** ✅ Завершен  
**Дата:** 8 октября 2025 г.  
**Версия:** 1.0  
**Изменения:** Добавлен таймаут для `/monitoring/check-updates` (ранее отсутствовал)
