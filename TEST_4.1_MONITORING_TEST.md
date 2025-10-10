# TEST 4.1: Проверка мониторинга (Пульс конкурента)

## Описание

Тестирование функционала мониторинга цен: проверка обнаружения изменений, отображения индикаторов и обновления истории.

## DoD

- ✅ После нажатия "Проверить обновления" цена на карточке товара изменилась на 1000₽
- ✅ Появился индикатор изменения (▼ для снижения, ▲ для роста)
- ✅ График истории цен перерисовался с новыми данными
- ✅ Карточка показывает процент изменения

## Реализация

### Тестовый эндпоинт

**Файл:** `server.js` (строки 598-632)  
**Маршрут:** `POST /monitoring/test-change`

```javascript
app.post(
  '/monitoring/test-change',
  asyncHandler(async (req, res) => {
    const items = Array.from(monitoringRegistry.values());
    
    if (items.length === 0) {
      return res.status(404).json({ error: 'Нет товаров в мониторинге' });
    }

    // Берём первый товар
    const firstItem = items[0];
    const newPrice = 1000;
    const oldPrice = firstItem.currentPrice || newPrice;
    const change = newPrice - oldPrice;
    const changePercent = oldPrice > 0 ? ((change / oldPrice) * 100).toFixed(1) : 0;

    // Обновляем данные
    firstItem.currentPrice = newPrice;
    firstItem.history = firstItem.history || [];
    firstItem.history.push({
      timestamp: new Date().toISOString(),
      price: newPrice,
      change: change,
      changePercent: parseFloat(changePercent)
    });

    // Сохраняем обновлённые данные
    monitoringRegistry.set(firstItem.id, firstItem);

    logger.info({ itemId: firstItem.id, newPrice, change, changePercent }, 'Test price change applied');

    res.json({
      message: 'Цена изменена для тестирования',
      item: firstItem,
      oldPrice,
      newPrice,
      change,
      changePercent: `${changePercent}%`
    });
  })
);
```

### Как это работает

1. **Находит первый товар:** `monitoringRegistry.values()[0]`
2. **Устанавливает новую цену:** `1000₽`
3. **Вычисляет изменение:**
   ```javascript
   change = newPrice - oldPrice
   changePercent = (change / oldPrice) * 100
   ```
4. **Добавляет запись в историю:**
   ```javascript
   {
     timestamp: "2025-10-08T12:34:56.789Z",
     price: 1000,
     change: -1990,         // например, если было 2990₽
     changePercent: -66.6   // снижение на 66.6%
   }
   ```
5. **Обновляет `currentPrice`:** `firstItem.currentPrice = 1000`

## Пошаговая инструкция по тестированию

### Шаг 1: Запустить сервер

```bash
npm start
```

**Ожидаемый вывод:**
```
[INFO] Server listening on http://localhost:3000
```

### Шаг 2: Открыть приложение

1. Откройте браузер
2. Перейдите: `http://localhost:3000/index.html`
3. Переключитесь на вкладку **"Мониторинг"**

### Шаг 3: Добавить товар в мониторинг

1. **Вставьте URL товара** (любой реальный URL):
   ```
   https://www.ozon.ru/product/example-123456
   ```
   или
   ```
   https://www.wildberries.ru/catalog/123456/detail.aspx
   ```

2. **Выберите маркетплейс:** Ozon / Wildberries / Яндекс Маркет

3. **Добавьте заметку** (опционально):
   ```
   Главный конкурент
   ```

4. **Нажмите "Добавить конкурента"**

**Ожидаемый результат:**
- ✅ Появилось сообщение "Товар успешно добавлен в список наблюдения"
- ✅ Карточка товара появилась ниже формы
- ✅ Показывается URL и время добавления
- ✅ Кнопка "Проверить обновления" стала видимой

**Важно:** Подождите 2-3 секунды, пока сервер загрузит начальные данные о товаре.

### Шаг 4: Вызвать тестовый эндпоинт

**Вариант A: Через curl (PowerShell)**

```powershell
Invoke-RestMethod -Uri "http://localhost:3000/monitoring/test-change" -Method POST -ContentType "application/json"
```

**Вариант B: Через Postman**

1. Откройте Postman
2. Метод: `POST`
3. URL: `http://localhost:3000/monitoring/test-change`
4. Нажмите "Send"

**Вариант C: Через DevTools Console**

1. Откройте DevTools (F12) → Console
2. Выполните:
   ```javascript
   fetch('http://localhost:3000/monitoring/test-change', {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' }
   })
   .then(r => r.json())
   .then(d => console.log('Test response:', d));
   ```

**Ожидаемый ответ:**

```json
{
  "message": "Цена изменена для тестирования",
  "item": {
    "id": "1",
    "productUrl": "https://...",
    "marketplace": "ozon",
    "currentPrice": 1000,
    "history": [
      {
        "timestamp": "2025-10-08T12:00:00.000Z",
        "price": 2990,
        "change": null,
        "changePercent": null
      },
      {
        "timestamp": "2025-10-08T12:05:00.000Z",
        "price": 1000,
        "change": -1990,
        "changePercent": -66.6
      }
    ]
  },
  "oldPrice": 2990,
  "newPrice": 1000,
  "change": -1990,
  "changePercent": "-66.6%"
}
```

### Шаг 5: Нажать "Проверить обновления"

1. **Вернитесь в браузер** с открытым приложением
2. **Нажмите кнопку "Проверить обновления"** под формой мониторинга

**Что происходит:**
- Кнопка становится неактивной ("Проверяю...")
- Отправляется `POST /monitoring/check-updates`
- Сервер проверяет все товары в мониторинге
- Фронтенд обновляет карточки товаров

### Шаг 6: Проверить DoD

#### ✅ DoD 1: Цена изменилась на 1000₽

**Где смотреть:** Карточка товара

**Ожидаемое:**
```
Текущая цена: 1000 ₽
```

**Было:**
```
Текущая цена: 2990 ₽  (или другое значение)
```

#### ✅ DoD 2: Появился индикатор изменения

**Где смотреть:** Рядом с ценой

**Ожидаемое:**
```
▼ -66.6%  (красный цвет — снижение)
```

Или если цена выросла:
```
▲ +15.2%  (зелёный цвет — рост)
```

**Классы Tailwind:**
- Снижение: `text-red-400` (красный)
- Рост: `text-green-400` (зелёный)

#### ✅ DoD 3: График перерисовался

**Где смотреть:** Под информацией о товаре

**Ожидаемое:**
- Новая точка на графике с ценой 1000₽
- Две точки соединены линией (если была предыдущая цена)
- Ось X: временные метки
- Ось Y: цены

**Технология:** Chart.js (если реализовано) или SVG/Canvas

#### ✅ DoD 4: Процент изменения отображается

**Где смотреть:** На карточке товара

**Ожидаемое:**
```
Изменение: -1990 ₽ (-66.6%)
```

## Проблемы и решения

### Проблема 1: "Нет товаров в мониторинге"

**Симптом:** При вызове `/monitoring/test-change` возвращается:
```json
{
  "error": "Нет товаров в мониторинге"
}
```

**Причина:** Товары не были добавлены через `/monitoring/add`

**Решение:**
1. Убедитесь, что вы добавили хотя бы один товар (Шаг 3)
2. Проверьте, что запрос на добавление прошёл успешно (status 201)

### Проблема 2: Карточка не обновляется

**Симптом:** После нажатия "Проверить обновления" цена не меняется

**Возможные причины:**
1. **JavaScript ошибка:** Откройте DevTools → Console, проверьте на ошибки
2. **Неверный item ID:** Фронтенд ищет карточку по `data-item-id`, но ID не совпадает
3. **Кэширование:** Браузер кэширует старый ответ

**Решение:**
1. Проверьте Console на ошибки
2. Убедитесь, что в карточке есть атрибут `data-item-id`:
   ```html
   <article data-item-id="1">
   ```
3. Обновите страницу (`Ctrl + F5`) и повторите с Шага 3

### Проблема 3: Индикатор не появляется

**Симптом:** Цена меняется, но нет ▼ или ▲

**Причина:** Фронтенд не реализует отображение индикатора

**Решение:** Проверьте код обработки ответа `/monitoring/check-updates` в `index.html`. Должен быть код типа:
```javascript
if (update.changePercent) {
  const icon = update.change < 0 ? '▼' : '▲';
  const color = update.change < 0 ? 'text-red-400' : 'text-green-400';
  // Показываем индикатор
}
```

### Проблема 4: График не обновляется

**Симптом:** История есть, но график не перерисовывается

**Причина:** График требует обновления данных Chart.js (или другой библиотеки)

**Решение:**
1. Проверьте, что график инициализирован: `chartInstance`
2. Обновите данные графика:
   ```javascript
   chartInstance.data.datasets[0].data = historyData;
   chartInstance.update();
   ```

## Тестовые сценарии

### Сценарий 1: Снижение цены

1. Добавить товар с ценой 2990₽
2. Вызвать `/monitoring/test-change` → цена станет 1000₽
3. Проверить обновления
4. **Ожидаемое:** ▼ -66.6% (красный)

### Сценарий 2: Рост цены

1. Добавить товар с ценой 500₽
2. Вызвать `/monitoring/test-change` → цена станет 1000₽
3. Проверить обновления
4. **Ожидаемое:** ▲ +100.0% (зелёный)

### Сценарий 3: Множественные изменения

1. Добавить товар
2. Вызвать `/monitoring/test-change` (первый раз)
3. Проверить обновления → 1000₽
4. **Изменить эндпоинт** на `newPrice = 800`
5. Вызвать снова
6. Проверить обновления → 800₽
7. **Ожидаемое:** График с 3 точками

### Сценарий 4: Нет изменений

1. Добавить товар с ценой 1000₽
2. Вызвать `/monitoring/test-change` → цена станет 1000₽
3. Проверить обновления
4. **Ожидаемое:** Изменение 0%, индикатор не показывается

## Архитектура мониторинга

### Серверная часть

**Хранилище:** `monitoringRegistry` (Map)
```javascript
monitoringRegistry = Map {
  "1" => {
    id: "1",
    productUrl: "https://...",
    marketplace: "ozon",
    status: "active",
    currentPrice: 1000,
    history: [
      { timestamp: "...", price: 2990, change: null },
      { timestamp: "...", price: 1000, change: -1990, changePercent: -66.6 }
    ]
  }
}
```

### Клиентская часть

**DOM структура карточки:**
```html
<article data-item-id="1" class="...">
  <div class="price">1000 ₽</div>
  <div class="indicator">▼ -66.6%</div>
  <canvas id="price-chart-1"></canvas>
</article>
```

## Расширение теста

### Добавление других изменений

Можно расширить `/monitoring/test-change` для тестирования других полей:

```javascript
// В server.js
firstItem.currentTitle = "НОВОЕ НАЗВАНИЕ";
firstItem.currentRating = 4.9;
firstItem.currentReviews = 1500;
```

### Тестирование недоступных товаров

См. [Test 4.5: "Живой" Мониторинг](docs/TEST_4.5_UNAVAILABLE_MONITORING.md)

## Связанные тесты

- [Test 4.5: Unavailable Monitoring](docs/TEST_4.5_UNAVAILABLE_MONITORING.md) — обработка недоступных товаров
- [Test 4.3: Data Integrity](docs/TEST_4.3_DATA_INTEGRITY.md) — целостность данных парсер→AI
- [Test 3.2: Slow Internet](TEST_3.2_SLOW_INTERNET.md) — таймаут для /monitoring/check-updates

---

**Статус:** ✅ Готов к тестированию  
**Дата:** 8 октября 2025 г.  
**Версия:** 1.0  
**Примечание:** Тестовый эндпоинт `/monitoring/test-change` уже реализован в `server.js` (строки 598-632)
