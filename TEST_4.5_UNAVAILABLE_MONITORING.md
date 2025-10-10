# TEST 4.5: "Живой" Мониторинг (Проверка на недоступность)

## Описание

Ручной тест функции мониторинга товаров: проверка, что при удалении товара с маркетплейса (или его недоступности) система **корректно обрабатывает ошибку** и **помечает товар как недоступный** в UI.

## DoD (Definition of Done)

✅ **При проверке удалённого товара на его карточке появляется плашка "Товар недоступен"**

- Система обрабатывает ошибку парсинга (товар удалён/недоступен)
- Товар помечается статусом `status: 'unavailable'`
- В UI появляется красная плашка с текстом "⚠️ Товар недоступен"
- Плашка содержит причину недоступности

## Почему это важно?

**Проблема:** Если товар конкурента удалён с маркетплейса, парсер выбрасывает ошибку. Без обработки этой ошибки:
- Пользователь не поймёт, почему нет обновлений
- Мониторинг будет показывать устаревшие данные
- Пользователь потратит время на ручную проверку

**Решение:** При ошибке парсинга помечаем товар как недоступный и показываем соответствующую плашку в UI.

## Реализация

### Backend: `server.js`

#### Маршрут: `POST /monitoring/check-updates`

**Расположение:** `server.js`, строки 636-730

**Логика обработки недоступности:**

```javascript
for (const item of items) {
  try {
    // Получаем актуальные данные с маркетплейса
    const freshData = await parseProductByMarketplace(item.productUrl, item.marketplace);
    
    if (!freshData || !freshData.price) {
      logger.warn({ itemId: item.id, url: item.productUrl }, 'Failed to fetch fresh data');
      
      // 🧪 TEST 4.5: Помечаем товар как недоступный
      if (item.status !== 'unavailable') {
        item.status = 'unavailable';
        item.unavailableSince = new Date().toISOString();
        monitoringRegistry.set(item.id, item);
        
        unavailableItems.push({
          id: item.id,
          title: item.currentTitle || 'Неизвестный товар',
          url: item.productUrl,
          reason: 'Не удалось получить данные о товаре'
        });
        
        logger.warn({ itemId: item.id, url: item.productUrl }, 'Item marked as unavailable');
      }
      
      continue;
    }

    // Если товар был недоступен, но теперь доступен - восстанавливаем статус
    if (item.status === 'unavailable') {
      item.status = 'active';
      delete item.unavailableSince;
      monitoringRegistry.set(item.id, item);
      logger.info({ itemId: item.id }, 'Item became available again');
    }
    
    // ... (остальная логика проверки изменений цены)
  } catch (error) {
    // Ошибка парсинга - помечаем как недоступный
    logger.error({ itemId: item.id, error: error.message }, 'Parse error');
    // ... (аналогичная логика помечания как unavailable)
  }
}
```

**Структура ответа:**

```json
{
  "message": "Проверено товаров: 3",
  "checked": 3,
  "updates": [
    {
      "id": "item-123",
      "title": "Товар A",
      "oldPrice": 2990,
      "newPrice": 2790,
      "change": -200,
      "changePercent": -6.7
    }
  ],
  "unavailable": [
    {
      "id": "item-456",
      "title": "Товар B (удалённый)",
      "url": "https://www.ozon.ru/product/deleted-123",
      "reason": "Не удалось получить данные о товаре"
    }
  ],
  "unavailableCount": 1
}
```

---

### Frontend: `index.html`

#### Обработка недоступных товаров

**Расположение:** `index.html`, строки 619-700

**Логика:**

1. При добавлении товара в мониторинг:
   ```javascript
   entry.dataset.status = data.item?.status || 'active';
   ```

2. При проверке обновлений:
   ```javascript
   if (data.unavailable && data.unavailable.length > 0) {
     data.unavailable.forEach(unavail => {
       const card = Array.from(cards).find(c => c.dataset.itemId === unavail.id);
       if (card) {
         card.dataset.status = 'unavailable';
         const statusDiv = card.querySelector('.monitoring-card-status');
         if (statusDiv) {
           statusDiv.innerHTML = `
             <div class="mt-2 p-3 bg-red-900/30 border border-red-700 rounded-lg">
               <p class="text-sm font-semibold text-red-400">⚠️ Товар недоступен</p>
               <p class="text-xs text-red-300 mt-1">${escapeHtml(unavail.reason || 'Не удалось загрузить данные')}</p>
             </div>
           `;
         }
       }
     });
   }
   ```

3. Вывод статистики:
   ```javascript
   let message = `Проверено товаров: ${data.checked}`;
   if (data.unavailableCount > 0) {
     message += `\n⚠️ Недоступно: ${data.unavailableCount}`;
   }
   monitoringStatus.textContent = message;
   ```

---

## Как проводить тест

### Подготовка

1. **Запустите сервер:**
   ```powershell
   node server.js
   ```

2. **Откройте `index.html` в браузере**

### Сценарий 1: Добавление недоступного товара (прямой тест)

**Цель:** Проверить, что система корректно обрабатывает недоступный товар при первой проверке.

#### Шаг 1: Добавьте товар в мониторинг

1. Откройте вкладку **"Мониторинг"**
2. Введите URL несуществующего товара:
   ```
   https://www.ozon.ru/product/deleted-nonexistent-999999999
   ```
3. Выберите маркетплейс: **Ozon**
4. Нажмите **"Добавить в мониторинг"**

**Ожидаемое поведение:**
- Товар добавлен в список мониторинга
- Карточка товара отображается без плашки (пока не проверяли)

#### Шаг 2: Проверьте обновления

1. Нажмите кнопку **"Проверить обновления"**
2. Дождитесь ответа (5-10 секунд)

**Ожидаемый результат:**

✅ **На карточке товара появилась красная плашка:**

```
┌─────────────────────────────────────┐
│ ⚠️ Товар недоступен                  │
│ Не удалось получить данные о товаре │
└─────────────────────────────────────┘
```

**Статус в шапке:**
```
Проверено товаров: 1
⚠️ Недоступно: 1
```

---

### Сценарий 2: Товар стал недоступен (динамический тест)

**Цель:** Проверить, что товар, который был доступен, корректно помечается как недоступный.

#### Шаг 1: Добавьте реальный товар

1. Откройте вкладку **"Мониторинг"**
2. Введите URL реального товара:
   ```
   https://www.wildberries.ru/catalog/12345678/detail.aspx
   ```
   (или любой другой реальный URL)
3. Нажмите **"Добавить в мониторинг"**
4. Нажмите **"Проверить обновления"**

**Ожидаемое поведение:**
- Товар доступен, данные загружены успешно
- Статус: `active`
- Плашки нет

#### Шаг 2: Симулируйте удаление товара

**Вариант A: Через тестовый эндпоинт (если добавлен)**

```powershell
# Пометить товар как недоступный вручную
Invoke-RestMethod -Uri "http://localhost:3000/monitoring/test-unavailable" -Method POST -Body (@{ itemId = "item-123" } | ConvertTo-Json) -ContentType "application/json"
```

**Вариант B: Измените URL на несуществующий**

1. Откройте DevTools (F12)
2. В консоли выполните:
   ```javascript
   // Найти карточку товара и изменить URL
   const card = document.querySelector('article[data-item-id]');
   const link = card.querySelector('a');
   link.href = 'https://www.wildberries.ru/catalog/99999999/detail.aspx'; // Несуществующий товар
   ```

#### Шаг 3: Проверьте обновления снова

1. Нажмите **"Проверить обновления"**
2. Дождитесь ответа

**Ожидаемый результат:**

✅ **На карточке товара появилась красная плашка:**

```
┌─────────────────────────────────────┐
│ ⚠️ Товар недоступен                  │
│ Не удалось получить данные о товаре │
└─────────────────────────────────────┘
```

**Логи сервера (должны содержать):**

```
WARN: Failed to fetch fresh data
WARN: Item marked as unavailable
```

---

### Сценарий 3: Товар снова стал доступен (восстановление)

**Цель:** Проверить, что товар автоматически восстанавливается, когда снова становится доступным.

#### Предусловие

Товар помечен как недоступный (из Сценария 2).

#### Шаг 1: Верните корректный URL

1. Откройте DevTools (F12)
2. В консоли выполните:
   ```javascript
   const card = document.querySelector('article[data-item-id]');
   const link = card.querySelector('a');
   link.href = 'https://www.wildberries.ru/catalog/12345678/detail.aspx'; // Реальный товар
   ```

#### Шаг 2: Проверьте обновления

1. Нажмите **"Проверить обновления"**
2. Дождитесь ответа

**Ожидаемый результат:**

✅ **Красная плашка исчезла**

✅ **Товар снова в статусе `active`**

**Логи сервера:**

```
INFO: Item became available again
```

---

## Чек-лист проверки

### Базовая проверка (DoD)

| Критерий | ✅/❌ | Комментарий |
|----------|------|-------------|
| **1. Плашка появляется** | ☐ | "⚠️ Товар недоступен" отображается на карточке |
| **2. Причина указана** | ☐ | Текст "Не удалось получить данные о товаре" |
| **3. Цвет корректен** | ☐ | Плашка красная (bg-red-900/30, border-red-700) |
| **4. Статус обновлён** | ☐ | `dataset.status === 'unavailable'` в HTML |
| **5. Статистика показана** | ☐ | "⚠️ Недоступно: 1" в шапке мониторинга |

**Результат:** ✅ PASS (все 5 критериев выполнены) / ❌ FAIL (хотя бы 1 критерий не выполнен)

---

### Расширенная проверка

| Критерий | ✅/❌ | Комментарий |
|----------|------|-------------|
| **6. Логи сервера** | ☐ | WARN: "Item marked as unavailable" |
| **7. Восстановление** | ☐ | Плашка исчезает, когда товар снова доступен |
| **8. Метаданные** | ☐ | `item.unavailableSince` установлен в ISO-формате |
| **9. API ответ** | ☐ | `response.unavailable` содержит массив недоступных товаров |
| **10. Обработка ошибок** | ☐ | Парсер не крашит приложение при ошибке |

---

## Примеры

### ✅ Хорошо: Плашка отображается корректно

**UI (карточка товара):**

```html
<article data-item-id="item-456" data-status="unavailable">
  <div class="flex items-center justify-between text-xs text-gray-500">
    <span>OZON</span>
    <span>08.10.2025, 14:30</span>
  </div>
  <a href="https://www.ozon.ru/product/deleted-123" class="text-indigo-300">
    https://www.ozon.ru/product/deleted-123
  </a>
  <p class="text-gray-300">Конкурент A (главный)</p>
  
  <!-- ✅ Плашка недоступности -->
  <div class="monitoring-card-status">
    <div class="mt-2 p-3 bg-red-900/30 border border-red-700 rounded-lg">
      <p class="text-sm font-semibold text-red-400">⚠️ Товар недоступен</p>
      <p class="text-xs text-red-300 mt-1">Не удалось получить данные о товаре</p>
    </div>
  </div>
</article>
```

**Статус в шапке:**

```
Проверено товаров: 3
Изменения цен: 1
⚠️ Недоступно: 1
```

**Результат:** ✅ PASS (DoD выполнен)

---

### ❌ Плохо: Плашка не появляется

**UI (карточка товара):**

```html
<article data-item-id="item-456" data-status="active">
  <!-- ... -->
  <div class="monitoring-card-status"></div> <!-- ❌ Пусто -->
</article>
```

**Статус в шапке:**

```
Проверено товаров: 3
Изменения цен: 0
```
(❌ Нет информации о недоступных товарах)

**Проблемы:**
- Плашка не отображается
- Статус не обновлён (`active` вместо `unavailable`)
- Пользователь не видит, что товар недоступен

**Результат:** ❌ FAIL (DoD не выполнен)

---

## Структура данных

### Backend: `monitoringRegistry`

**Товар в мониторинге (доступный):**

```javascript
{
  id: 'mon-1696780800000-abc123',
  productUrl: 'https://www.ozon.ru/product/123',
  marketplace: 'ozon',
  currentPrice: 2990,
  currentTitle: 'Bluetooth-колонка JBL',
  currentRating: 4.7,
  currentReviews: 150,
  notes: 'Главный конкурент',
  status: 'active', // ✅
  addedAt: '2025-10-08T10:00:00.000Z',
  history: []
}
```

**Товар в мониторинге (недоступный):**

```javascript
{
  id: 'mon-1696780800000-abc123',
  productUrl: 'https://www.ozon.ru/product/deleted-999',
  marketplace: 'ozon',
  currentPrice: 2990,
  currentTitle: 'Удалённый товар',
  notes: 'Бывший конкурент',
  status: 'unavailable', // ❌
  unavailableSince: '2025-10-08T12:30:00.000Z', // 🕒 Время пометки
  addedAt: '2025-10-08T10:00:00.000Z',
  history: []
}
```

---

### API Response: `POST /monitoring/check-updates`

**Успешный ответ (с недоступными товарами):**

```json
{
  "message": "Проверено товаров: 3",
  "checked": 3,
  "updates": [
    {
      "id": "mon-123",
      "title": "Товар A",
      "oldPrice": 2990,
      "newPrice": 2790,
      "change": -200,
      "changePercent": -6.7,
      "url": "https://www.ozon.ru/product/123"
    }
  ],
  "unavailable": [
    {
      "id": "mon-456",
      "title": "Товар B (удалённый)",
      "url": "https://www.ozon.ru/product/deleted-999",
      "reason": "Не удалось получить данные о товаре"
    }
  ],
  "unavailableCount": 1
}
```

---

## Тестовый эндпоинт (опционально)

Для упрощения тестирования можно добавить тестовый маршрут:

### `POST /monitoring/test-change`

**Назначение:** Симулировать изменение статуса товара (для тестирования).

**Добавить в `server.js`:**

```javascript
// 🧪 TEST 4.5: Тестовый эндпоинт для симуляции недоступности
app.post('/monitoring/test-unavailable', asyncHandler(async (req, res) => {
  const { itemId } = req.body;
  
  if (!itemId) {
    return res.status(400).json({ error: 'itemId обязателен' });
  }
  
  const item = monitoringRegistry.get(itemId);
  
  if (!item) {
    return res.status(404).json({ error: 'Товар не найден' });
  }
  
  // Помечаем как недоступный
  item.status = 'unavailable';
  item.unavailableSince = new Date().toISOString();
  monitoringRegistry.set(itemId, item);
  
  logger.info({ itemId }, 'TEST: Item marked as unavailable manually');
  
  res.json({
    message: 'Товар помечен как недоступный',
    item: {
      id: item.id,
      status: item.status,
      unavailableSince: item.unavailableSince
    }
  });
}));
```

**Использование:**

```powershell
# Получить список товаров
$items = Invoke-RestMethod -Uri "http://localhost:3000/monitoring/list" -Method GET

# Пометить первый товар как недоступный
$itemId = $items.items[0].id
Invoke-RestMethod -Uri "http://localhost:3000/monitoring/test-unavailable" -Method POST -Body (@{ itemId = $itemId } | ConvertTo-Json) -ContentType "application/json"

# Проверить обновления
Invoke-RestMethod -Uri "http://localhost:3000/monitoring/check-updates" -Method POST
```

---

## Критерии PASS/FAIL

### ✅ PASS (DoD выполнен)

**Базовая проверка:**
1. ✅ Плашка "⚠️ Товар недоступен" отображается на карточке
2. ✅ Причина недоступности указана ("Не удалось получить данные о товаре")
3. ✅ Цвет плашки красный (bg-red-900/30)
4. ✅ Статус карточки обновлён (`data-status="unavailable"`)
5. ✅ Статистика показывает количество недоступных товаров

**Расширенная проверка:**
6. ✅ Логи сервера содержат "Item marked as unavailable"
7. ✅ Товар восстанавливается, когда снова становится доступным
8. ✅ `item.unavailableSince` записан в ISO-формате
9. ✅ API возвращает массив `unavailable` с деталями
10. ✅ Парсер не крашит приложение при ошибке

---

### ❌ FAIL (DoD не выполнен)

**Хотя бы один из случаев:**

1. ❌ **Плашка не появляется**
   - Карточка товара выглядит так же, как у доступного товара
   - `.monitoring-card-status` пустой

2. ❌ **Статус не обновлён**
   - `data-status` остался `"active"` вместо `"unavailable"`

3. ❌ **Ошибка крашит приложение**
   - Сервер возвращает 500 Internal Server Error
   - Логи содержат Unhandled Exception

4. ❌ **Статистика не показана**
   - Нет информации о недоступных товарах в статусе

5. ❌ **Товар не восстанавливается**
   - После возвращения доступности плашка не исчезает
   - Статус остаётся `"unavailable"`

---

## Связанные тесты

- **Test 1.2: Empty Data** - обработка пустых данных из парсера
- **Test 3.2: Slow Internet** - таймаут 15 секунд для проверки обновлений
- **Test 4.1: Monitoring Test** - базовая функциональность мониторинга

---

## Примечания

### Причины недоступности

**Возможные причины:**

1. **Товар удалён с маркетплейса**
   - Парсер возвращает 404 Not Found
   - `freshData === null`

2. **Товар закончился**
   - HTML-страница есть, но цена отсутствует
   - `freshData.price === null`

3. **Изменилась структура HTML**
   - Парсер не может найти селектор цены
   - `freshData.price === undefined`

4. **Сетевая ошибка**
   - Таймаут запроса
   - Маркетплейс недоступен

### Как отличить причины?

**В будущем можно добавить:**

```javascript
if (!freshData) {
  reason = 'Товар удалён или страница недоступна (404)';
} else if (!freshData.price) {
  reason = 'Цена не найдена (товар закончился или изменилась структура)';
}
```

---

## Шаблон отчёта

```markdown
## Test 4.5: "Живой" Мониторинг (Недоступность)

Дата: 8 октября 2025 г.
Метод: Ручной тест (UI + логи сервера)

### Сценарий 1: Добавление недоступного товара
URL: https://www.ozon.ru/product/deleted-999
Результат: ✅ PASS
- Плашка появилась: ✅
- Причина указана: ✅
- Статус обновлён: ✅
- Логи сервера: ✅ WARN "Item marked as unavailable"

### Сценарий 2: Товар стал недоступен
URL: https://www.wildberries.ru/catalog/12345678/detail.aspx → изменён на несуществующий
Результат: ✅ PASS
- Плашка появилась после проверки: ✅
- `unavailableSince` записан: ✅ "2025-10-08T12:30:00.000Z"

### Сценарий 3: Товар снова стал доступен
URL: восстановлен корректный
Результат: ✅ PASS
- Плашка исчезла: ✅
- Статус изменён на "active": ✅
- Логи: ✅ INFO "Item became available again"

### Итого:
DoD: ✅ ВЫПОЛНЕН (плашка появляется при недоступности)
Все 3 сценария: ✅ PASS (100%)
```

---

**Статус:** ✅ Готов к ручному тестированию  
**Дата:** 8 октября 2025 г.  
**Версия:** 1.0  
**Тип:** Ручной тест (требует визуальной проверки UI)

**Примечание:** Функционал уже реализован в коде (backend + frontend), документация описывает, как его протестировать.
