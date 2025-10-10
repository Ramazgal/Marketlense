# TEST 3.1: Нервный пользователь

## Описание

Предотвращение множественных кликов по кнопкам во время выполнения асинхронных операций.

## DoD

- ✅ При нажатии на кнопку "Анализ" она становится неактивной до завершения запроса
- ✅ При нажатии на кнопку "Поиск" она становится неактивной до завершения запроса
- ✅ При нажатии на кнопку "Добавить в мониторинг" она становится неактивной до завершения запроса

## Реализация

### Расположение кода

**Файл:** `index.html`  
**Секция:** JavaScript обработчики событий (строки 274-620)

### Паттерн блокировки кнопки

Для каждой кнопки используется единый паттерн:

```javascript
const button = form.querySelector('.button-class');
form.addEventListener('submit', async (event) => {
    event.preventDefault();
    
    // 🔒 Блокировка кнопки в начале
    if (button) button.disabled = true;

    try {
        // ... выполнение асинхронной операции ...
    } catch (error) {
        // ... обработка ошибок ...
    } finally {
        // ✅ Разблокировка кнопки после завершения
        if (button) button.disabled = false;
    }
});
```

### Детали реализации

#### 1. Кнопка "Анализ" (analyze-btn)

**Строки:** 272-358

```javascript
const analyzeButton = analyzeForm.querySelector('.analyze-submit');
analyzeForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    
    // Блокировка кнопки при клике
    if (analyzeButton) analyzeButton.disabled = true;

    try {
        // ... логика анализа товара ...
    } catch (error) {
        // ... обработка ошибок ...
    } finally {
        // Разблокировка кнопки после завершения
        if (analyzeButton) analyzeButton.disabled = false;
    }
});
```

#### 2. Кнопка "Поиск" (search-tops-btn)

**Строки:** 411-504

```javascript
const searchButton = searchForm.querySelector('.search-submit');
searchForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    
    // Блокировка кнопки при клике
    if (searchButton) searchButton.disabled = true;

    try {
        // ... логика поиска лидеров ...
    } catch (error) {
        // ... обработка ошибок ...
    } finally {
        // Разблокировка кнопки после завершения
        if (searchButton) searchButton.disabled = false;
    }
});
```

#### 3. Кнопка "Добавить в мониторинг" (add-to-monitoring-btn)

**Строки:** 510-620

```javascript
const monitoringButton = monitoringForm.querySelector('.monitoring-submit');
monitoringForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    
    // Блокировка кнопки при клике
    if (monitoringButton) monitoringButton.disabled = true;

    try {
        // ... логика добавления в мониторинг ...
    } catch (error) {
        // ... обработка ошибок ...
    } finally {
        // Разблокировка кнопки после завершения
        if (monitoringButton) monitoringButton.disabled = false;
    }
});
```

## UX эффект

### До нажатия
- Кнопка активна, доступна для клика
- Курсор: `cursor-pointer`
- Цвет: яркий градиент

### Во время запроса
- Кнопка неактивна (`disabled = true`)
- Курсор: `cursor-not-allowed`
- Цвет: серый/затемнённый
- Статус: "Отправляем запрос..." / "Ищем топовые карточки..." / "Сохраняем карточку..."

### После завершения
- Кнопка снова активна (`disabled = false`)
- Возврат к исходному состоянию

## Тестирование

### Автоматические тесты

```powershell
.\scripts\test-nervous-user.ps1
```

**Проверяет:**
1. ✅ Analyze button: disabled = true at start
2. ✅ Analyze button: disabled = false in finally
3. ✅ Search button: disabled = true at start
4. ✅ Search button: disabled = false in finally
5. ✅ Monitoring button: disabled = true at start
6. ✅ Monitoring button: disabled = false in finally
7. ✅ Server stability

### Ручное тестирование

1. **Открыть `index.html` в браузере**
2. **Тест 1: Анализ товара**
   - Ввести ссылку на товар (например, Ozon)
   - Нажать кнопку "Анализ"
   - **Ожидаемое поведение:**
     - Кнопка становится серой и неактивной
     - Невозможно кликнуть повторно
     - После завершения (успех или ошибка) кнопка снова активна

3. **Тест 2: Поиск лидеров**
   - Ввести ключевое слово (например, "ноутбук")
   - Нажать кнопку "Искать"
   - **Ожидаемое поведение:**
     - Кнопка блокируется на время запроса
     - После получения результатов кнопка разблокируется

4. **Тест 3: Добавление в мониторинг**
   - Ввести ссылку на карточку конкурента
   - Нажать кнопку "Добавить"
   - **Ожидаемое поведение:**
     - Кнопка блокируется
     - После успешного добавления форма очищается, кнопка разблокируется

### Проверка множественных кликов

**Сценарий:** Быстрые повторные клики (spam clicking)

1. Открыть DevTools (F12) → Network → Throttling → **Slow 3G**
2. Нажать кнопку "Анализ" **10 раз подряд быстро**
3. **Ожидаемое поведение:**
   - Отправляется только 1 запрос (виден в Network tab)
   - Кнопка остаётся заблокированной до завершения
   - Дополнительные клики игнорируются

## Результаты тестирования

```
========== TEST 3.1: Nervous User ==========

Test 1: Code Review - Button Disabling Logic
  [PASS] Analyze button: disabled = true at start
  [PASS] Analyze button: disabled = false in finally
  [PASS] Search button: disabled = true at start
  [PASS] Search button: disabled = false in finally
  [PASS] Monitoring button: disabled = true at start
  [PASS] Monitoring button: disabled = false in finally

Test 2: Server Stability
  [PASS] Server running correctly

========== RESULTS ==========
Passed: 7/7 (100%)
Failed: 0
```

## Архитектурные решения

### Почему `finally` блок?

```javascript
try {
    // Запрос к API
} catch (error) {
    // Обработка ошибки
} finally {
    // ✅ Выполнится ВСЕГДА (успех, ошибка, таймаут)
    button.disabled = false;
}
```

**Преимущества:**
- ✅ Гарантирует разблокировку даже при исключениях
- ✅ Работает при таймаутах (AbortController)
- ✅ Срабатывает при network errors
- ✅ Не дублирует код в `try` и `catch`

### Почему проверка `if (button)`?

```javascript
if (button) button.disabled = true;
```

**Защита:**
- Предотвращает ошибку, если элемент не найден
- Безопасная работа при динамическом удалении DOM
- Graceful degradation

### CSS стили для disabled

Tailwind автоматически применяет стили для `disabled`:

```css
button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
    pointer-events: none;
}
```

## Интеграция с таймаутами

Блокировка кнопки работает совместно с 15-секундным таймаутом:

```javascript
const abortController = new AbortController();
const timeoutId = setTimeout(() => abortController.abort(), 15000);

try {
    const response = await fetch(url, {
        signal: abortController.signal
    });
    clearTimeout(timeoutId);
    // ...
} catch (fetchError) {
    clearTimeout(timeoutId);
    if (fetchError.name === 'AbortError') {
        throw new Error('Сервер слишком долго не отвечает. Попробуйте позже.');
    }
    throw fetchError;
} finally {
    // ✅ Кнопка разблокируется даже при таймауте
    button.disabled = false;
}
```

## Edge Cases

### 1. Валидация перед запросом

```javascript
if (!productUrl) {
    // ❌ Выход из функции без finally
    // ⚠️ Но кнопка еще не была заблокирована!
    return;
}

// ✅ Блокировка ПОСЛЕ валидации
if (analyzeButton) analyzeButton.disabled = true;
```

**Решение:** Ранний выход (`return`) выполняется **до** блокировки кнопки, поэтому кнопка остаётся активной.

### 2. Форма сброшена (reset)

```javascript
monitoringForm.reset(); // Очищает форму
```

**Поведение:** `form.reset()` не влияет на `button.disabled`, поэтому кнопка корректно разблокируется в `finally`.

### 3. Навигация пользователя

Если пользователь уходит со страницы во время запроса:
- Браузер автоматически отменяет fetch
- `finally` всё равно выполняется
- Но это не важно, так как страница уже выгружена

## Accessibility (A11y)

### Screen readers

```html
<button disabled aria-busy="true">
    Загрузка...
</button>
```

**Рекомендация для будущего:** Добавить атрибут `aria-busy="true"` при блокировке для screen readers.

## Связанные тесты

- [Test 1.1: URL Validation](docs/TEST_1.1_URL_VALIDATION.md)
- [Test 1.2: Empty Data Handling](docs/TEST_1.2_EMPTY_DATA.md)
- [Test 2.1: AI Format Validation](TEST_2.1_AI_FORMAT.md)
- [Test 4.3: Data Integrity](docs/TEST_4.3_DATA_INTEGRITY.md)

---

**Статус:** ✅ Завершен (функционал уже был реализован)  
**Дата:** 8 октября 2025 г.  
**Версия:** 1.0
