module.exports = {
  apps: [
    {
      name: 'marketlens-api',
      script: './server.js',
      instances: 'max', // Использовать все CPU ядра
      exec_mode: 'cluster',
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'development',
        PORT: 3000
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000,
        HOST: '0.0.0.0'
      },
      error_file: './logs/pm2-error.log',
      out_file: './logs/pm2-out.log',
      log_file: './logs/pm2-combined.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      time: true,
      merge_logs: true,
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      listen_timeout: 30000, // 30 секунд для запуска
      kill_timeout: 5000,
      cron_restart: '0 4 * * *', // Перезапуск каждый день в 4:00
      wait_ready: false,
      shutdown_with_message: true
    }
  ]
};
