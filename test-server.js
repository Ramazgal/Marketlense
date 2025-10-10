// Simple test server to validate Amvera API
require('dotenv').config();
const express = require('express');
const axios = require('axios');

const app = express();
app.use(express.json());
app.use(express.static('.'));

console.log('Starting test server...');
console.log('AMVERA_API_KEY present:', !!process.env.AMVERA_API_KEY);

app.post('/test-strategy', async (req, res) => {
  console.log('Received request:', req.body);
  
  try {
    const systemPrompt = `You are an AI consultant for MarketLens. Respond in JSON format with: {"risks": ["risk1"], "pricing": ["price1"], "marketing": ["idea1"], "todo": ["task1"]}`;
    const userPrompt = `Product: wireless headphones 2990 rubles, Rating 4.8`;
    
    console.log('Sending request to Amvera API...');
    
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
      timeout: 30000
    });
    
    console.log('Got response from Amvera');
    const aiResponse = response.data?.choices?.[0]?.message?.content;
    console.log('AI Response:', aiResponse);
    
    const strategyData = JSON.parse(aiResponse);
    console.log('Parsed JSON:', strategyData);
    
    res.json({ success: true, strategy: strategyData });
  } catch (error) {
    console.error('Error:', error.message);
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    }
    res.status(500).json({ error: error.message });
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(3000, '0.0.0.0', () => {
  console.log('✅ Test server running on port 3000');
});
