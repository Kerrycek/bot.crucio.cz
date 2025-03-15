# Jednoduchý návod na zprovoznění Telegram bota

Zde je jednoduchý návod krok za krokem, jak zprovoznit váš Telegram bot:

## 1. Nastavení Telegram bota

1. Otevřete Telegram a vyhledejte @BotFather
2. Pošlete mu příkaz `/newbot`
3. Zadejte jméno bota a uživatelské jméno (musí končit na "bot")
4. BotFather vám pošle token - ten si uložte

## 2. Získání chat_id

1. Pošlete zprávu svému botovi nebo ho přidejte do skupiny
2. Navštivte URL: `https://api.telegram.org/bot<VÁŠ_TOKEN>/getUpdates`
3. V odpovědi najdete `chat_id` pro vaše konverzace

## 3. Nastavení konfiguračního souboru

Upravte soubor `config/settings.yml`:
```
telegram:
  bot_token: "VÁŠ_TELEGRAM_BOT_TOKEN"
  chat_ids:
    - 123456789  # ID prvního chatu
    - 987654321  # ID druhého chatu (pokud potřebujete)

users:
  - username: "admin"
    password: "bezpečné_heslo_1"
  - username: "user2"
    password: "bezpečné_heslo_2"  # Volitelné
```

## 4. Instalace závislostí: 
```
cd /var/www/crucio.cz/bot
bundle install

Vytvořte soubor /etc/systemd/system/telegram-bot.service

[Unit]
Description=Telegram Bot Service
After=network.target

[Service]
User=www-data
WorkingDirectory=/var/www/crucio.cz/bot
ExecStart=/usr/local/bin/bundle exec puma
Restart=always
Environment=RACK_ENV=production

[Install]
WantedBy=multi-user.target


systemctl enable telegram-bot
systemctl start telegram-bot
```

## 5. configy apache
```
<VirtualHost *:80>
    ServerName bot.crucio.cz
    Redirect permanent / https://bot.crucio.cz/
</VirtualHost>
```

```
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerName bot.crucio.cz
    
    ErrorLog ${APACHE_LOG_DIR}/bot.crucio.cz-ssl-error.log
    CustomLog ${APACHE_LOG_DIR}/bot.crucio.cz-ssl-access.log combined
    
    ProxyPass / http://localhost:4567/
    ProxyPassReverse / http://localhost:4567/
    
    SSLEngine on
    Include /etc/letsencrypt/options-ssl-apache.conf
    SSLCertificateFile /etc/letsencrypt/live/bot.crucio.cz/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/bot.crucio.cz/privkey.pem
</VirtualHost>
</IfModule>
```
```
a2enmod proxy proxy_http ssl rewrite
a2ensite bot.crucio.cz.conf bot.crucio.cz-le-ssl.conf
systemctl restart apache2

```

# Test zdraví služby
```
curl -X GET http://localhost:4567/health
```

# Test odeslání zprávy
```
curl -X POST http://localhost:4567/send_message \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"bezpečné_heslo_1","message":"Testovací zpráva"}'
```

```
# Test zdraví služby
curl -X GET https://bot.crucio.cz/health
```

```
# Test odeslání zprávy
curl -X POST https://bot.crucio.cz/send_message \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"bezpečné_heslo_1","message":"Testovací zpráva přes doménu"}'
```










