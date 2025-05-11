require_relative './lib/gmail_client'
require 'yaml'
require 'httparty'
require 'time'
require 'google/apis/gmail_v1'

# Load configuration
config_path = '/etc/rails-env/.config.yml'
config = YAML.load_file(config_path) || {}

api_key                = config['OPENPHONE_API']
from_number            = config['OPENPHONE_PHONE_NUMBER_ALERTS']
to_number              = config['OPENPHONE_PHONE_NUMBER']
gmail_credentials_path = config['GMAIL_CREDENTIALS_PATH'] || '/etc/rails-env/gmail-credentials.json'

# Handle GMAIL_SENDER_KEYWORDS
raw_keywords = config.fetch('GMAIL_SENDER_KEYWORDS', '')
sender_keywords_array = if raw_keywords.strip.empty?
  ['state.gov', 'ssa.gov']
else
  raw_keywords.split(/\s*,\s*/).map(&:downcase)
end

# Initialize Gmail client
client = GmailClient.new(credentials_path: gmail_credentials_path)

# Gmail search query (limit to past 8 hours)
query = 'is:unread newer_than:8h'

# Fetch matching emails
messages = client.fetch_matching_messages(query: query)

messages.each do |msg|
  sender = msg[:from]&.downcase || 'unknown'

  if sender_keywords_array.any? { |keyword| sender.include?(keyword) }
    snippet = msg[:snippet].to_s[0..100]
    subject = msg[:subject] || 'No Subject'

    sms_text = "Email from #{sender}: #{subject} - #{snippet}"

    payload = {
      from: from_number,
      to: [to_number],
      content: sms_text
    }

    timestamp = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S %z')
    puts "[#{timestamp}] Sending SMS: #{sms_text}"

    response = HTTParty.post(
      "https://api.openphone.com/v1/messages",
      headers: {
        "Authorization" => api_key,
        "Content-Type" => "application/json"
      },
      body: payload.to_json
    )

    puts "[#{timestamp}] SMS sent: HTTP #{response.code}"

    # ✅ Mark the message as read
    client_service = client.instance_variable_get(:@service)
    modify_request = Google::Apis::GmailV1::ModifyMessageRequest.new(remove_label_ids: ['UNREAD'])
    client_service.modify_message('me', msg[:id], modify_request)

  else
    puts "[GmailClient] Skipped: #{sender} — no keyword match"
  end
end
