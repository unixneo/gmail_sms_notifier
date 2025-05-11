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
gmail_address          = config['GMAIL_ADDRESS'] || raise("Missing GMAIL_ADDRESS in config")

# Handle GMAIL_SENDER_KEYWORDS
raw_keywords = config.fetch('GMAIL_SENDER_KEYWORDS', '')
sender_keywords_array = if raw_keywords.strip.empty?
  ['state.gov', 'ssa.gov']
else
  raw_keywords.split(/\s*,\s*/).map(&:downcase)
end

# Initialize Gmail client
client = GmailClient.new(credentials_path: gmail_credentials_path, gmail_address: gmail_address)
gmail_service = client.instance_variable_get(:@service)

# Ensure the "SMS Sent" label exists and get its ID
def ensure_label(service, label_name)
  existing = service.list_user_labels('me').labels.find { |l| l.name == label_name }
  return existing.id if existing

  new_label = Google::Apis::GmailV1::Label.new(
    name: label_name,
    label_list_visibility: 'labelShow',
    message_list_visibility: 'show'
  )
  service.create_user_label('me', new_label).id
end

sms_sent_label_id = ensure_label(gmail_service, 'SMS Sent')

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

    timestamp = Time.now.getlocal('+07:00').strftime('%Y-%m-%d %H:%M:%S %z')
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

    # ✅ Mark as read and apply "SMS Sent" label
    modify_request = Google::Apis::GmailV1::ModifyMessageRequest.new(
      remove_label_ids: ['UNREAD'],
      add_label_ids: [sms_sent_label_id]
    )
    gmail_service.modify_message('me', msg[:id], modify_request)

  else
    puts "[#{Time.now.getlocal('+07:00').strftime('%Y-%m-%d %H:%M:%S %z')}] [GmailClient] Skipped: #{sender} — no keyword match"
  end
end
