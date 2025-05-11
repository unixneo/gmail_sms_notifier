require 'google/apis/gmail_v1'
require 'googleauth'

class GmailClient
  APPLICATION_NAME = 'Gmail SMS Notifier'
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY

  def initialize(credentials_path:, gmail_address:)
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(credentials_path),
      scope: SCOPE
    )

    authorizer.sub = gmail_address
    authorizer.fetch_access_token!

    @service = Google::Apis::GmailV1::GmailService.new
    @service.authorization = authorizer
  end

  def fetch_matching_messages(query:)
    timestamp = -> { Time.now.utc.strftime('%Y-%m-%d %H:%M:%S %z') }

    puts "[#{timestamp.call}] [GmailClient] Searching for messages matching: #{query}"
    result = @service.list_user_messages('me', q: query, max_results: 5)
    return [] unless result.messages

    puts "[#{timestamp.call}] [GmailClient] Found #{result.messages.size} matching message(s)"

    result.messages.map do |msg_meta|
      msg = @service.get_user_message('me', msg_meta.id)
      headers_raw = msg.payload.headers || []
      headers = headers_raw.map { |h| [h.name, h.value] }.to_h
      puts "[#{timestamp.call}] [GmailClient] Processing message: #{msg.id}, From: #{headers['From']}, Subject: #{headers['Subject']}"
      {
        id: msg.id,
        from: headers['From'],
        subject: headers['Subject'],
        snippet: msg.snippet
      }
    end
  end
end
