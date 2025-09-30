'use strict';

// --- MarketLens Backend Server v5.0 (with real Gemini AI) ---
require('dotenv').config();
const express = require('express');
const axios = require('axios');
const cheerio = require('cheerio');
const cors = require('cors');
const pino = require('pino');
const { z } = require('zod');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: process.env.NODE_ENV === 'production' ? undefined : { target: 'pino-pretty' }
});

// --- Проверка наличия API ключа ---
if (!process.env.GEMINI_API_KEY) {
  logger.error(
    'КРИТИЧЕСКАЯ ОШИБКА: API ключ для Gemini не найден. Создайте файл .env и добавьте в него GEMINI_API_KEY=ВАШ_КЛЮЧ'
  );
  process.exit(1);
}

// --- Настройки окружения ---
const PORT = Number(process.env.PORT || 3000);
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-1.5-flash';
const REQUEST_TIMEOUT_MS = Number(process.env.REQUEST_TIMEOUT_MS || 10000);

// --- Инициализация AI ---
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const aiModel = genAI.getGenerativeModel({ model: GEMINI_MODEL });

const app = express();
app.use(cors());
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

  return {
    marketplace: payload.marketplace,
    product: productSnapshot,
    competitors,
    generatedAt: new Date().toISOString()
  };
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

  const prompt = `Ты — AI-консультант маркетплейсов MarketLens. На основе данных ниже подготовь структурированную стратегию.

=== Наши факты ===
${userEvidence.map((item, idx) => `${idx + 1}. ${item}`).join('\n')}

=== Конкуренты ===
${competitorsEvidence.map((item, idx) => `${idx + 1}. ${item}`).join('\n')}

${focusLine}

Тональность ответа: ${tone}.

Структура ответа:
1. Ключевые риски.
2. Рекомендации по цене и ассортименту.
3. Идеи по маркетингу и продвижению.
4. Приоритетный To-Do список (3-5 задач).

Используй маркированные списки, дай конкретику и цифры, если они есть.`;

  const result = await aiModel.generateContent(prompt);
  return result.response.text();
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

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
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
    const payload = analyzeSchema.parse({
      marketplace: req.query.marketplace,
      productUrl: req.query.url || req.query.productUrl,
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
    const snapshot = {
      id,
      ...payload,
      status: 'active',
      createdAt: new Date().toISOString()
    };

    monitoringRegistry.set(id, snapshot);

    res.status(201).json({ message: 'Товар добавлен в мониторинг', item: snapshot });
  })
);

app.post(
  '/monitoring/add',
  asyncHandler(async (req, res) => {
    const payload = monitoringCreateSchema.parse(req.body);
    const id = String(monitoringIdSeq++);
    const snapshot = {
      id,
      ...payload,
      status: 'active',
      createdAt: new Date().toISOString()
    };

    monitoringRegistry.set(id, snapshot);

    res.status(201).json({
      message: 'Товар успешно добавлен в список наблюдения',
      item: snapshot
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
    res.json({ message: 'Запись удалена', id });
  })
);

app.post(
  '/strategize',
  asyncHandler(async (req, res) => {
    const payload = strategizeSchema.parse(req.body);

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

app.listen(PORT, () => {
  logger.info(`✅ AI Сервер MarketLens v5.0 (с Gemini) запущен на порту ${PORT}`);
});
