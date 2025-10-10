'use strict';

// --- MarketLens Backend Server v6.1 (Amvera GPT-4.1 Edition) ---
require('dotenv').config();
const express = require('express');
const axios = require('axios');
const cheerio = require('cheerio');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const pino = require('pino');
const { z } = require('zod');
const fs = require('fs');

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: process.env.NODE_ENV === 'production' ? undefined : { target: 'pino-pretty' }
});

// --- Проверка наличия API ключа Amvera ---
if (!process.env.AMVERA_API_KEY) {
  logger.error(
    'КРИТИЧЕСКАЯ ОШИБКА: API ключ для Amvera не найден. Создайте файл .env и добавьте в него AMVERA_API_KEY=ВАШ_КЛЮЧ'
  );
  process.exit(1);
}

// --- Настройки окружения ---
const PORT = Number(process.env.PORT || 3000);
const HOST = process.env.HOST || '0.0.0.0';
const REQUEST_TIMEOUT_MS = Number(process.env.REQUEST_TIMEOUT_MS || 10000);
const DB_FILE_PATH = './monitoring_db.json';
const IS_PRODUCTION = process.env.NODE_ENV === 'production';

// --- Функция для проверки Amvera API ---
async function testAmveraAPI() {
  if (!process.env.AMVERA_API_KEY) {
    throw new Error('AMVERA_API_KEY не найден в переменных окружения');
  }

  try {
    const response = await axios.post('https://llm.api.amvera.ru/v1/chat/completions', {
      model: 'gpt-4.1',
      messages: [
        { role: 'user', content: 'test' }
      ],
      max_tokens: 10
    }, {
      headers: {
        'X-Auth-Token': `Bearer ${process.env.AMVERA_API_KEY}`,
        'Content-Type': 'application/json'
      },
      timeout: 5000 // 5 секунд для health check
    });
    
    return response.data?.choices?.[0]?.message?.content || 'ok';
  } catch (error) {
    logger.error({ error: error.message, status: error?.response?.status }, 'Amvera API test failed');
    throw new Error(`Amvera API error: ${error.message}`);
  }
}

const app = express();

// --- Безопасность (Helmet) ---
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://cdn.jsdelivr.net"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"]
    }
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

// --- CORS ---
const corsOptions = {
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true,
  optionsSuccessStatus: 200
};
app.use(cors(corsOptions));

// --- Rate Limiting ---
const limiter = rateLimit({
  windowMs: Number(process.env.RATE_LIMIT_WINDOW_MS || 900000), // 15 минут
  max: Number(process.env.RATE_LIMIT_MAX_REQUESTS || 100), // лимит запросов
  message: { error: 'Слишком много запросов с вашего IP, попробуйте позже' },
  standardHeaders: true,
  legacyHeaders: false
});

// Применяем rate limiting только к API эндпоинтам
app.use('/api/', limiter);
app.use('/analyze', limiter);
app.use('/search', limiter);
app.use('/strategize', limiter);
app.use('/monitoring/', limiter);

app.use(express.json({ limit: '1mb' }));

const monitoringRegistry = new Map();
let monitoringIdSeq = 1;

const httpClient = axios.create({
  timeout: REQUEST_TIMEOUT_MS,
  headers: {
    'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36',
    Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp'
  }
});

httpClient.interceptors.response.use(
  (response) => response,
  (error) => {
    logger.warn({ err: error?.message, url: error?.config?.url }, 'HTTP запрос завершился ошибкой');
    return Promise.reject(error);
  }
);

// --- Система персистентного хранения данных мониторинга ---

/**
 * Загружает данные мониторинга из файла при старте сервера
 * @returns {void}
 */
function loadMonitoringData() {
  try {
    if (fs.existsSync(DB_FILE_PATH)) {
      const fileContent = fs.readFileSync(DB_FILE_PATH, 'utf8');
      const data = JSON.parse(fileContent);
      
      if (data && Array.isArray(data.items)) {
        // Восстанавливаем Map из массива объектов
        data.items.forEach(item => {
          monitoringRegistry.set(item.id, item);
        });
        
        // Восстанавливаем счётчик ID
        if (data.nextId) {
          monitoringIdSeq = data.nextId;
        }
        
        logger.info({ itemsCount: data.items.length, nextId: monitoringIdSeq }, 'Данные мониторинга загружены из файла');
      }
    } else {
      logger.info('Файл данных мониторинга не найден, используется пустой список');
    }
  } catch (error) {
    logger.error({ error: error.message }, 'Ошибка при загрузке данных мониторинга, используется пустой список');
  }
}

/**
 * Сохраняет текущие данные мониторинга в файл
 * @returns {void}
 */
function saveMonitoringData() {
  try {
    const data = {
      items: Array.from(monitoringRegistry.values()),
      nextId: monitoringIdSeq,
      lastUpdated: new Date().toISOString()
    };
    
    fs.writeFileSync(DB_FILE_PATH, JSON.stringify(data, null, 2), 'utf8');
    logger.debug({ itemsCount: data.items.length }, 'Данные мониторинга сохранены в файл');
  } catch (error) {
    logger.error({ error: error.message }, 'Ошибка при сохранении данных мониторинга');
  }
}

const marketplaceSchema = z.enum(['ozon', 'wildberries', 'yandex_market']).describe('Поддерживаемые маркетплейсы');

const analyzeSchema = z.object({
  marketplace: marketplaceSchema,
  productUrl: z.string().url('Некорректный URL товара'),
  withCompetitors: z.boolean().optional().default(true)
});

const searchSchema = z.object({
  marketplace: marketplaceSchema.optional(),
  query: z.string().min(2, 'Минимум 2 символа').max(80, 'Максимум 80 символов'),
  limit: z.number().int().min(1).max(20).optional().default(5)
});

const monitoringCreateSchema = z.object({
  marketplace: marketplaceSchema,
  productUrl: z.string().url('Некорректный URL товара'),
  notes: z.string().max(280, 'Максимум 280 символов заметок').optional()
});

const strategizeSchema = z.object({
  userEvidence: z
    .array(z.string().min(5))
    .min(1, 'Нужен минимум один факт о вашем товаре')
    .max(10, 'Не более 10 фактов о вашем товаре'),
  competitorsEvidence: z
    .array(z.string().min(5))
    .min(1, 'Добавьте хотя бы одного конкурента')
    .max(10, 'Не более 10 конкурентов'),
  tone: z.enum(['formal', 'friendly', 'analytical']).optional().default('analytical'),
  focus: z.array(z.enum(['pricing', 'marketing', 'logistics', 'promotion', 'reviews'])).optional().default([])
});

const localCatalog = {
  ozon: [
    {
      sku: 'oz-10001',
      title: 'Беспроводные наушники MarketLens Air',
      url: 'https://www.ozon.ru/product/example-oz-10001',
      price: 3590,
      rating: 4.8,
      reviews: 328,
      brand: 'MarketLens',
      category: 'Электроника'
    },
    {
      sku: 'oz-10002',
      title: 'Умная колонка MarketLens Home',
      url: 'https://www.ozon.ru/product/example-oz-10002',
      price: 6490,
      rating: 4.6,
      reviews: 189,
      brand: 'MarketLens',
      category: 'Умный дом'
    }
  ],
  wildberries: [
    {
      sku: 'wb-54712891',
      title: 'Рюкзак городской MarketLens Urban 24L',
      url: 'https://www.wildberries.ru/catalog/54712891/detail.aspx',
      price: 2890,
      rating: 4.7,
      reviews: 742,
      brand: 'MarketLens',
      category: 'Аксессуары'
    },
    {
      sku: 'wb-54712892',
      title: 'Термокружка MarketLens Steel 500ml',
      url: 'https://www.wildberries.ru/catalog/54712892/detail.aspx',
      price: 1290,
      rating: 4.9,
      reviews: 981,
      brand: 'MarketLens',
      category: 'Дом и кухня'
    }
  ],
  yandex_market: [
    {
      sku: 'ym-882001',
      title: 'MarketLens RoboVac X1',
      url: 'https://market.yandex.ru/product--882001',
      price: 24990,
      rating: 4.5,
      reviews: 204,
      brand: 'MarketLens',
      category: 'Бытовая техника'
    }
  ]
};

function extractNumber(value) {
  if (!value) return null;
  const cleaned = String(value).replace(/[^0-9.,]/g, '').replace(',', '.');
  const asNumber = Number.parseFloat(cleaned);
  return Number.isNaN(asNumber) ? null : asNumber;
}

async function parseOzon(productUrl) {
  const fallback = {
    title: 'Товар на Ozon',
    price: null,
    rating: null,
    reviews: null,
    availability: 'unknown',
    url: productUrl
  };

  try {
    const { data } = await httpClient.get(productUrl);
    const $ = cheerio.load(data);

    const title = $('h1').first().text().trim() || fallback.title;
    const priceText = $('[class*="price"]:contains("₽")').first().text();
    const ratingText = $('[data-widget="rating"] span').first().text();
    const reviewsText = $('[data-widget="reviews"] span').first().text();

    return {
      title,
      price: extractNumber(priceText) || fallback.price,
      rating: extractNumber(ratingText) || fallback.rating,
      reviews: extractNumber(reviewsText) || fallback.reviews,
      availability: $('button:contains("В корзину")').length ? 'in_stock' : 'unknown',
      url: productUrl
    };
  } catch (error) {
    logger.warn({ err: error?.message, productUrl }, 'Не удалось спарсить страницу Ozon, используем заглушку');
    return fallback;
  }
}

async function parseWildberries(productUrl) {
  const fallback = {
    title: 'Товар на Wildberries',
    price: null,
    rating: null,
    reviews: null,
    availability: 'unknown',
    url: productUrl
  };

  try {
    const { data } = await httpClient.get(productUrl);
    const $ = cheerio.load(data);

    const title = $('h1').first().text().trim() || fallback.title;
    const priceText = $('ins').first().text();
    const ratingText = $('[class*="product-rating"] span').first().text();
    const reviewsText = $('[class*="product-review"] span').first().text();

    return {
      title,
      price: extractNumber(priceText) || fallback.price,
      rating: extractNumber(ratingText) || fallback.rating,
      reviews: extractNumber(reviewsText) || fallback.reviews,
      availability: $('button:contains("Добавить в корзину")').length ? 'in_stock' : 'unknown',
      url: productUrl
    };
  } catch (error) {
    logger.warn({ err: error?.message, productUrl }, 'Не удалось спарсить страницу Wildberries, используем заглушку');
    return fallback;
  }
}

async function parseYandexMarket(productUrl) {
  const fallback = {
    title: 'Товар на Яндекс Маркете',
    price: null,
    rating: null,
    reviews: null,
    availability: 'unknown',
    url: productUrl
  };

  try {
    const { data } = await httpClient.get(productUrl);
    const $ = cheerio.load(data);

    const title = $('h1').first().text().trim() || fallback.title;
    const priceText = $('[data-auto="main-price"]').first().text();
    const ratingText = $('[data-auto="rating-badge"] span').first().text();
    const reviewsText = $('[data-auto="rating-review-count"] span').first().text();

    return {
      title,
      price: extractNumber(priceText) || fallback.price,
      rating: extractNumber(ratingText) || fallback.rating,
      reviews: extractNumber(reviewsText) || fallback.reviews,
      availability: $('[data-auto="buy-button"]').length ? 'in_stock' : 'unknown',
      url: productUrl
    };
  } catch (error) {
    logger.warn({ err: error?.message, productUrl }, 'Не удалось спарсить страницу Яндекс Маркета, используем заглушку');
    return fallback;
  }
}

const parserMap = {
  ozon: parseOzon,
  wildberries: parseWildberries,
  yandex_market: parseYandexMarket
};

const normalizeBoolean = (value) => {
  if (value === undefined || value === null) return undefined;
  if (typeof value === 'boolean') return value;
  if (Array.isArray(value)) return normalizeBoolean(value[value.length - 1]);

  const normalized = String(value).trim().toLowerCase();
  if (['true', '1', 'yes', 'on'].includes(normalized)) return true;
  if (['false', '0', 'no', 'off'].includes(normalized)) return false;
  return undefined;
};

async function fulfillAnalyzeRequest(payload) {
  const parseFn = parserMap[payload.marketplace];

  const productSnapshot = await parseFn(payload.productUrl);
  const competitors = payload.withCompetitors ? buildCompetitorSummary(productSnapshot, payload.marketplace) : [];

  // 🧪 TEST 4.3: Логирование после парсинга
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🔍 [TEST 4.3] ДАННЫЕ ПОСЛЕ ПАРСИНГА (/analyze)');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📦 Товар:');
  console.log(`   Название: ${productSnapshot.title}`);
  console.log(`   Цена:     ${productSnapshot.price} руб`);
  console.log(`   Рейтинг:  ${productSnapshot.rating} ★`);
  console.log(`   Отзывы:   ${productSnapshot.reviews}`);
  console.log(`   Статус:   ${productSnapshot.availability}`);
  console.log(`\n👥 Конкуренты: ${competitors.length} шт`);
  competitors.forEach((c, idx) => {
    console.log(`   ${idx + 1}. ${c.title} - ${c.price} руб, ${c.rating} ★, ${c.reviews} отзывов`);
  });
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  return {
    marketplace: payload.marketplace,
    product: productSnapshot,
    competitors,
    generatedAt: new Date().toISOString()
  };
}

// Helper-функция для парсинга товара по URL и маркетплейсу
async function parseProductByMarketplace(productUrl, marketplace) {
  const parseFn = parserMap[marketplace];
  if (!parseFn) {
    throw new Error(`Неподдерживаемый маркетплейс: ${marketplace}`);
  }
  return await parseFn(productUrl);
}

function searchLocalDataset(query, marketplace, limit) {
  const normalizedQuery = query.toLowerCase();
  const marketplaces = marketplace ? [marketplace] : Object.keys(localCatalog);
  const results = [];

  marketplaces.forEach((mp) => {
    const candidates = localCatalog[mp] || [];
    candidates.forEach((item) => {
      if (results.length >= limit) return;
      if (item.title.toLowerCase().includes(normalizedQuery) || item.category.toLowerCase().includes(normalizedQuery)) {
        results.push({ marketplace: mp, ...item });
      }
    });
  });

  return results.slice(0, limit);
}

function buildCompetitorSummary(productSnapshot, marketplace) {
  const dataset = localCatalog[marketplace] || [];
  const filtered = dataset.filter((item) => item.url !== productSnapshot.url).slice(0, 3);
  if (filtered.length > 0) {
    return filtered;
  }

  return [
    {
      marketplace,
      sku: `${marketplace}-generic-1`,
      title: 'Конкурент — базовая модель',
      url: `${productSnapshot.url}?cmp=1`,
      price: productSnapshot.price ? Math.round(productSnapshot.price * 0.95) : null,
      rating: productSnapshot.rating ? Math.max(productSnapshot.rating - 0.2, 3.5) : 4.2,
      reviews: productSnapshot.reviews ? Math.max(productSnapshot.reviews - 50, 10) : 120,
      brand: 'Generic',
      category: 'Аналогичная категория'
    }
  ];
}

async function generateRealAiStrategy(userEvidence, competitorsEvidence, tone, focus) {
  const focusLine = focus.length
    ? `Фокус анализа: ${focus.map((item) => `#${item}`).join(' ')}.`
    : 'Фокус анализа: общий обзор конкурентной стратегии.';

  const systemPrompt = `Ты — AI-консультант маркетплейсов MarketLens. На основе данных подготовь структурированную стратегию в формате JSON.

Структура JSON ответа:
{
  "risks": ["риск 1", "риск 2", ...],
  "pricing": ["рекомендация 1", "рекомендация 2", ...],
  "marketing": ["идея 1", "идея 2", ...],
  "todo": ["задача 1", "задача 2", "задача 3"]
}

Используй конкретику и цифры, если они есть.`;

  const userPrompt = `=== Наши факты ===
${userEvidence.map((item, idx) => `${idx + 1}. ${item}`).join('\n')}

=== Конкуренты ===
${competitorsEvidence.map((item, idx) => `${idx + 1}. ${item}`).join('\n')}

${focusLine}

Тональность ответа: ${tone}.`;

  try {
    // Проверка наличия API ключа Amvera
    if (!process.env.AMVERA_API_KEY) {
      throw new Error('AMVERA_API_KEY не найден в переменных окружения');
    }

    // Запрос к Amvera API
    const response = await axios.post('https://llm.api.amvera.ru/v1/chat/completions', {
      model: 'gpt-4.1',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      response_format: { type: 'json_object' }
    }, {
      headers: {
        'X-Auth-Token': `Bearer ${process.env.AMVERA_API_KEY}`,
        'Content-Type': 'application/json'
      },
      timeout: REQUEST_TIMEOUT_MS
    });

    // Извлечение ответа
    const aiResponse = response.data?.choices?.[0]?.message?.content;
    
    if (!aiResponse || aiResponse.trim().length === 0) {
      throw new Error('AI вернул пустой ответ');
    }

    // Парсинг JSON ответа
    let strategyData;
    try {
      strategyData = JSON.parse(aiResponse);
    } catch (parseError) {
      logger.error({ error: parseError.message, response: aiResponse.substring(0, 200) }, 'Ошибка парсинга JSON от AI');
      throw new Error('AI вернул ответ в некорректном JSON формате');
    }

    // Валидация структуры
    if (!strategyData.risks || !strategyData.pricing || !strategyData.marketing || !strategyData.todo) {
      throw new Error('AI вернул JSON с неполной структурой');
    }

    // Форматирование ответа в текст для обратной совместимости
    const formattedResponse = `
📊 **Ключевые риски:**
${strategyData.risks.map((risk, idx) => `${idx + 1}. ${risk}`).join('\n')}

💰 **Рекомендации по цене и ассортименту:**
${strategyData.pricing.map((rec, idx) => `${idx + 1}. ${rec}`).join('\n')}

🚀 **Идеи по маркетингу и продвижению:**
${strategyData.marketing.map((idea, idx) => `${idx + 1}. ${idea}`).join('\n')}

✅ **Приоритетный To-Do список:**
${strategyData.todo.map((task, idx) => `${idx + 1}. ${task}`).join('\n')}
`.trim();

    return formattedResponse;

  } catch (error) {
    logger.error({ 
      err: error?.message, 
      response: error?.response?.data,
      status: error?.response?.status 
    }, 'Ошибка при генерации AI-стратегии через Amvera');
    
    // Если это ошибка от Amvera API
    if (error?.response?.status === 401) {
      throw new Error('Неверный API ключ Amvera. Проверьте AMVERA_API_KEY в .env');
    }
    
    if (error?.response?.status === 429) {
      throw new Error('Превышен лимит запросов к Amvera API. Попробуйте позже.');
    }
    
    if (error?.response?.status >= 500) {
      throw new Error('Сервер Amvera API временно недоступен. Попробуйте позже.');
    }
    
    // Общая ошибка
    throw new Error(`AI не смог сгенерировать стратегию: ${error.message}`);
  }
}

const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

app.get('/', (req, res) => {
  res.json({
    name: 'MarketLens Backend',
    version: '5.0',
    status: 'online',
    documentation: '/docs',
    endpoints: ['/health', '/analyze', '/search', '/monitoring', '/strategize']
  });
});

// --- Расширенный Health Check для мониторинга ---
app.get('/health', async (req, res) => {
  const healthcheck = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    version: '6.0.0',
    checks: {}
  };

  // Проверка Amvera AI API
  try {
    await testAmveraAPI();
    healthcheck.checks.ai = 'ok';
  } catch (error) {
    healthcheck.checks.ai = 'error';
    healthcheck.status = 'degraded';
  }

  // Проверка дискового пространства (если есть файл БД)
  try {
    if (fs.existsSync(DB_FILE_PATH)) {
      const stats = fs.statSync(DB_FILE_PATH);
      healthcheck.checks.database = {
        status: 'ok',
        size: `${(stats.size / 1024).toFixed(2)} KB`
      };
    } else {
      healthcheck.checks.database = { status: 'ok', size: '0 KB' };
    }
  } catch (error) {
    healthcheck.checks.database = { status: 'error', message: error.message };
    healthcheck.status = 'degraded';
  }

  // Проверка памяти
  const memUsage = process.memoryUsage();
  healthcheck.checks.memory = {
    status: 'ok',
    heapUsed: `${(memUsage.heapUsed / 1024 / 1024).toFixed(2)} MB`,
    heapTotal: `${(memUsage.heapTotal / 1024 / 1024).toFixed(2)} MB`
  };

  const statusCode = healthcheck.status === 'ok' ? 200 : 503;
  res.status(statusCode).json(healthcheck);
});

app.post(
  '/analyze',
  asyncHandler(async (req, res) => {
    const payload = analyzeSchema.parse(req.body);
    const result = await fulfillAnalyzeRequest(payload);
    res.json(result);
  })
);

app.get(
  '/analyze',
  asyncHandler(async (req, res) => {
    const productUrl = req.query.url || req.query.productUrl;

    // Валидация формата URL перед парсингом
    const validPatterns = [
      /ozon\.ru\/product\//i,
      /wildberries\.ru\/catalog\//i,
      /market\.yandex\.ru\/product/i
    ];

    const isValidUrl = validPatterns.some((pattern) => pattern.test(productUrl));

    if (!isValidUrl) {
      return res.status(400).json({
        error: 'Неверный формат ссылки. Убедитесь, что это ссылка на карточку товара.'
      });
    }

    const payload = analyzeSchema.parse({
      marketplace: req.query.marketplace,
      productUrl,
      withCompetitors: normalizeBoolean(req.query.withCompetitors)
    });

    const result = await fulfillAnalyzeRequest(payload);
    res.json(result);
  })
);

app.get(
  '/search',
  asyncHandler(async (req, res) => {
    const params = searchSchema.parse({
      marketplace: req.query.marketplace,
      query: req.query.q || req.query.query,
      limit: req.query.limit ? Number(req.query.limit) : undefined
    });

    const results = searchLocalDataset(params.query, params.marketplace, params.limit);

    res.json({
      query: params.query,
      marketplace: params.marketplace || 'all',
      count: results.length,
      results
    });
  })
);

app.get('/monitoring', (req, res) => {
  const items = Array.from(monitoringRegistry.values()).sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  res.json({ items, total: items.length });
});

app.post(
  '/monitoring',
  asyncHandler(async (req, res) => {
    const payload = monitoringCreateSchema.parse(req.body);
    const id = String(monitoringIdSeq++);
    
    // Создаем запись сразу, данные подгрузим асинхронно
    const snapshot = {
      id,
      ...payload,
      status: 'active',
      createdAt: new Date().toISOString(),
      currentPrice: null,
      currentTitle: null,
      currentRating: null,
      currentReviews: null,
      history: []
    };

    monitoringRegistry.set(id, snapshot);

    res.status(201).json({ message: 'Товар добавлен в мониторинг', item: snapshot });
    
    // Асинхронно подгружаем данные в фоне
    parseProductByMarketplace(payload.productUrl, payload.marketplace)
      .then(initialData => {
        if (initialData?.price) {
          snapshot.currentPrice = initialData.price;
          snapshot.currentTitle = initialData.title;
          snapshot.currentRating = initialData.rating;
          snapshot.currentReviews = initialData.reviews;
          snapshot.history.push({
            timestamp: new Date().toISOString(),
            price: initialData.price,
            change: null,
            changePercent: null
          });
          monitoringRegistry.set(id, snapshot);
          logger.info({ itemId: id, price: initialData.price }, 'Initial price loaded');
        }
      })
      .catch(err => logger.error({ itemId: id, error: err.message }, 'Failed to load initial price'));
  })
);

app.post(
  '/monitoring/add',
  asyncHandler(async (req, res) => {
    const payload = monitoringCreateSchema.parse(req.body);
    const id = String(monitoringIdSeq++);
    
    // Создаем запись сразу, данные подгрузим асинхронно
    const snapshot = {
      id,
      ...payload,
      status: 'active',
      createdAt: new Date().toISOString(),
      currentPrice: null,
      currentTitle: null,
      currentRating: null,
      currentReviews: null,
      history: []
    };

    monitoringRegistry.set(id, snapshot);

    // Сохраняем в файл
    saveMonitoringData();

    res.status(201).json({
      message: 'Товар успешно добавлен в список наблюдения',
      item: snapshot
    });
    
    // Асинхронно подгружаем данные в фоне
    parseProductByMarketplace(payload.productUrl, payload.marketplace)
      .then(initialData => {
        if (initialData?.price) {
          snapshot.currentPrice = initialData.price;
          snapshot.currentTitle = initialData.title;
          snapshot.currentRating = initialData.rating;
          snapshot.currentReviews = initialData.reviews;
          snapshot.history.push({
            timestamp: new Date().toISOString(),
            price: initialData.price,
            change: null,
            changePercent: null
          });
          monitoringRegistry.set(id, snapshot);
          saveMonitoringData(); // Сохраняем после загрузки начальных данных
          logger.info({ itemId: id, price: initialData.price }, 'Initial price loaded');
        }
      })
      .catch(err => logger.error({ itemId: id, error: err.message }, 'Failed to load initial price'));
  })
);

// Тестовый маршрут для имитации изменения цены
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
    saveMonitoringData();

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

// Проверка обновлений для всех товаров в мониторинге
app.post(
  '/monitoring/check-updates',
  asyncHandler(async (req, res) => {
    const items = Array.from(monitoringRegistry.values());
    
    if (items.length === 0) {
      return res.json({ message: 'Нет товаров в мониторинге', updates: [], unavailable: [], checked: 0, unavailableCount: 0 });
    }

    const updates = [];
    const unavailableItems = [];

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

        const oldPrice = item.currentPrice;
        const newPrice = freshData.price;

        // Проверяем, изменилась ли цена
        if (oldPrice !== newPrice) {
          const change = newPrice - oldPrice;
          const changePercent = oldPrice > 0 ? ((change / oldPrice) * 100).toFixed(1) : 0;

          // Обновляем данные товара
          item.currentPrice = newPrice;
          item.currentTitle = freshData.title || item.currentTitle;
          item.currentRating = freshData.rating || item.currentRating;
          item.currentReviews = freshData.reviews || item.currentReviews;
          
          // Добавляем запись в историю
          item.history = item.history || [];
          item.history.push({
            timestamp: new Date().toISOString(),
            price: newPrice,
            change: change,
            changePercent: parseFloat(changePercent)
          });

          // Сохраняем обновлённые данные
          monitoringRegistry.set(item.id, item);

          updates.push({
            id: item.id,
            title: item.currentTitle,
            oldPrice,
            newPrice,
            change,
            changePercent: parseFloat(changePercent),
            priceDirection: change < 0 ? 'down' : 'up'
          });

          logger.info({ itemId: item.id, oldPrice, newPrice, change, changePercent }, 'Price changed');
        }
      } catch (error) {
        logger.error({ itemId: item.id, error: error.message }, 'Error checking item updates');
        
        // 🧪 TEST 4.5: При ошибке парсинга помечаем товар как недоступный
        if (item.status !== 'unavailable') {
          item.status = 'unavailable';
          item.unavailableSince = new Date().toISOString();
          monitoringRegistry.set(item.id, item);
          
          unavailableItems.push({
            id: item.id,
            title: item.currentTitle || 'Неизвестный товар',
            url: item.productUrl,
            reason: error.message || 'Ошибка парсинга'
          });
          
          logger.warn({ itemId: item.id, error: error.message }, 'Item marked as unavailable due to error');
        }
      }
    }

    // Сохраняем все изменения после проверки всех товаров
    saveMonitoringData();

    // Собираем ALL unavailable items (включая те, что были недоступны ранее)
    const allUnavailable = items
      .filter(item => item.status === 'unavailable')
      .map(item => ({
        id: item.id,
        title: item.currentTitle || 'Неизвестный товар',
        url: item.productUrl,
        reason: 'Товар недоступен'
      }));

    res.json({
      message: updates.length > 0 ? `Найдено изменений: ${updates.length}` : 'Изменений цен не обнаружено',
      updates,
      unavailable: allUnavailable,
      checked: items.length,
      unavailableCount: allUnavailable.length
    });
  })
);

app.delete(
  '/monitoring/:id',
  asyncHandler(async (req, res) => {
    const id = req.params.id;
    if (!monitoringRegistry.has(id)) {
      return res.status(404).json({ error: 'Запись не найдена' });
    }

    monitoringRegistry.delete(id);
    saveMonitoringData();
    res.json({ message: 'Запись удалена', id });
  })
);

app.post(
  '/strategize',
  asyncHandler(async (req, res) => {
    const payload = strategizeSchema.parse(req.body);

    // 🧪 TEST 4.3: Логирование перед отправкой в AI
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🤖 [TEST 4.3] ДАННЫЕ ПЕРЕД ОТПРАВКОЙ В AI (/strategize)');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 Наши факты (userEvidence):');
    payload.userEvidence.forEach((fact, idx) => {
      console.log(`   ${idx + 1}. ${fact}`);
    });
    console.log('\n🎯 Факты о конкурентах (competitorsEvidence):');
    payload.competitorsEvidence.forEach((fact, idx) => {
      console.log(`   ${idx + 1}. ${fact}`);
    });
    console.log(`\n⚙️  Тональность: ${payload.tone}`);
    console.log(`⚙️  Фокус: ${payload.focus.length > 0 ? payload.focus.join(', ') : 'общий'}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    const strategy = await generateRealAiStrategy(
      payload.userEvidence,
      payload.competitorsEvidence,
      payload.tone,
      payload.focus
    );

    res.json({
      strategy,
      generatedAt: new Date().toISOString()
    });
  })
);

app.use((req, res) => {
  res.status(404).json({ error: 'Маршрут не найден' });
});

app.use((err, req, res, _next) => {
  logger.error({ err: err.message, stack: err.stack }, 'Необработанная ошибка');

  if (err instanceof z.ZodError) {
    return res.status(400).json({ error: 'Ошибка валидации', issues: err.issues });
  }

  res.status(err.status || 500).json({ error: 'Внутренняя ошибка сервера' });
});

// --- Загрузка сохранённых данных при запуске ---
loadMonitoringData();

app.listen(PORT, HOST, () => {
  logger.info({
    version: '6.1.0',
    port: PORT,
    host: HOST,
    environment: process.env.NODE_ENV || 'development',
    aiProvider: 'Amvera GPT-4.1',
    rateLimiting: 'enabled',
    security: 'helmet enabled'
  }, `🚀 Amvera GPT Сервер MarketLens v6.1 запущен`);
});
