require 'sinatra'
require 'telegram/bot'
require 'yaml'
require 'json'
require 'logger'

# Vytvoření adresáře pro logy, pokud neexistuje
log_dir = File.join(File.dirname(__FILE__), 'logs')
Dir.mkdir(log_dir) unless Dir.exist?(log_dir)

# Inicializace loggeru
logger = Logger.new(File.join(log_dir, 'application.log'))

# Načtení konfigurace
CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), 'config', 'settings.yml'))

# Nastavení Sinatra
set :bind, '0.0.0.0'
set :port, 4567

# Funkce pro ověření uživatele
def authenticate(username, password)
  CONFIG['users'].any? do |user|
    user['username'] == username && user['password'] == password
  end
end

# Funkce pro odeslání zprávy přes Telegram
def send_telegram_message(message)
  token = CONFIG['telegram']['bot_token']
  chat_ids = CONFIG['telegram']['chat_ids']
  
  Telegram::Bot::Client.run(token) do |bot|
    chat_ids.each do |chat_id|
      begin
        bot.api.send_message(chat_id: chat_id, text: message)
        logger.info("Zpráva úspěšně odeslána do chatu #{chat_id}")
      rescue => e
        logger.error("Chyba při odesílání zprávy do chatu #{chat_id}: #{e.message}")
      end
    end
  end
end

# Endpoint pro přijetí POST požadavku
post '/send_message' do
  # Parsování JSON dat z požadavku
  request_payload = JSON.parse(request.body.read)
  
  username = request_payload['username']
  password = request_payload['password']
  message = request_payload['message']
  
  # Kontrola, zda jsou všechny parametry přítomny
  halt 400, { error: 'Chybí povinné parametry' }.to_json unless username && password && message
  
  # Ověření uživatele
  unless authenticate(username, password)
    halt 401, { error: 'Neplatné přihlašovací údaje' }.to_json
  end
  
  # Odeslání zprávy přes Telegram
  begin
    send_telegram_message(message)
    { success: true, message: 'Zpráva byla úspěšně odeslána' }.to_json
  rescue => e
    halt 500, { error: "Chyba při odesílání zprávy: #{e.message}" }.to_json
  end
end

# Jednoduchý endpoint pro kontrolu, zda služba běží
get '/health' do
  { status: 'ok' }.to_json
end 