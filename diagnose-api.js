// Диагностика подключения к Amvera API
require('dotenv').config();
const axios = require('axios');
const dns = require('dns').promises;

console.log('🔍 Диагностика подключения к Amvera API\n');

// Проверка 1: API ключ
console.log('1️⃣ Проверка API ключа:');
if (process.env.AMVERA_API_KEY) {
  console.log('   ✅ AMVERA_API_KEY найден');
  console.log('   📏 Длина:', process.env.AMVERA_API_KEY.length, 'символов');
  console.log('   🔑 Начало:', process.env.AMVERA_API_KEY.substring(0, 50) + '...');
} else {
  console.log('   ❌ AMVERA_API_KEY не найден в .env!');
  process.exit(1);
}

// Проверка 2: DNS
console.log('\n2️⃣ Проверка DNS:');
const domains = [
  'llm.api.amvera.ru',
  'api.amvera.ru',
  'amvera.ru'
];

async function checkDNS() {
  for (const domain of domains) {
    try {
      const addresses = await dns.resolve4(domain);
      console.log(`   ✅ ${domain} → ${addresses.join(', ')}`);
    } catch (error) {
      console.log(`   ❌ ${domain} → ${error.code || error.message}`);
    }
  }
}

// Проверка 3: HTTP подключение
console.log('\n3️⃣ Проверка HTTP подключения:');
const endpoints = [
  'https://llm.api.amvera.ru/v1/chat/completions',
  'https://api.amvera.ru/v1/chat/completions',
  'https://llm.amvera.ru/v1/chat/completions'
];

async function checkHTTP() {
  for (const url of endpoints) {
    try {
      console.log(`\n   🔗 Попытка: ${url}`);
      const response = await axios.post(url, {
        model: 'gpt-4.1',
        messages: [
          { role: 'user', content: 'test' }
        ],
        max_tokens: 5
      }, {
        headers: {
          'X-Auth-Token': `Bearer ${process.env.AMVERA_API_KEY}`,
          'Content-Type': 'application/json'
        },
        timeout: 10000,
        validateStatus: () => true // Принимаем любой статус
      });
      
      console.log(`   📊 Статус: ${response.status} ${response.statusText}`);
      
      if (response.status === 200) {
        console.log('   ✅ УСПЕХ! API работает');
        console.log('   📝 Ответ:', JSON.stringify(response.data, null, 2).substring(0, 200));
        return url;
      } else if (response.status === 401) {
        console.log('   ⚠️  401 Unauthorized - проверьте API ключ');
      } else if (response.status === 404) {
        console.log('   ❌ 404 Not Found - неправильный endpoint');
      } else {
        console.log('   ⚠️  Неожиданный статус');
        console.log('   📝 Ответ:', JSON.stringify(response.data, null, 2).substring(0, 200));
      }
    } catch (error) {
      if (error.code === 'ENOTFOUND') {
        console.log(`   ❌ DNS ошибка: домен не найден`);
      } else if (error.code === 'ETIMEDOUT') {
        console.log(`   ❌ Timeout: сервер не отвечает`);
      } else if (error.code === 'ECONNREFUSED') {
        console.log(`   ❌ Connection refused: сервер отклонил подключение`);
      } else {
        console.log(`   ❌ Ошибка: ${error.message}`);
      }
    }
  }
  return null;
}

// Проверка 4: Альтернативные API
console.log('\n4️⃣ Проверка альтернативных API (если Amvera недоступен):');
async function checkAlternatives() {
  // OpenRouter API (может работать с GPT-4)
  console.log('\n   🔗 OpenRouter API: https://openrouter.ai/api/v1/chat/completions');
  console.log('   💡 Альтернатива: можно использовать OpenRouter с GPT-4');
  
  // Local LLM
  console.log('\n   🔗 Local LLM: http://localhost:11434/api/chat (Ollama)');
  console.log('   💡 Альтернатива: можно запустить локальную модель');
}

// Запуск всех проверок
async function runDiagnostics() {
  await checkDNS();
  const workingEndpoint = await checkHTTP();
  await checkAlternatives();
  
  console.log('\n' + '='.repeat(60));
  
  if (workingEndpoint) {
    console.log('✅ ДИАГНОСТИКА ЗАВЕРШЕНА: API работает!');
    console.log('🎯 Рабочий endpoint:', workingEndpoint);
  } else {
    console.log('❌ ДИАГНОСТИКА ЗАВЕРШЕНА: API недоступен');
    console.log('\n💡 Возможные причины:');
    console.log('   1. Нет интернет-соединения');
    console.log('   2. Домен llm.api.amvera.ru не существует или изменился');
    console.log('   3. API ключ истёк или неверный');
    console.log('   4. Сервис Amvera временно недоступен');
    console.log('\n🔧 Рекомендации:');
    console.log('   1. Проверьте документацию Amvera: https://docs.amvera.ru');
    console.log('   2. Свяжитесь с поддержкой Amvera');
    console.log('   3. Используйте mock-server.js для тестирования UI');
    console.log('   4. Рассмотрите альтернативные API (OpenRouter, local Ollama)');
  }
  
  console.log('='.repeat(60));
}

runDiagnostics().catch(console.error);
