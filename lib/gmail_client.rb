require 'google/apis/gmail_v1'
require 'googleauth'
require 'yaml'

class GmailClient
  APPLICATION_NAME = 'Gmail SMS Notifier'
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY
  CONFIG_PATH = '/etc/rails-env/.config.yml'

  def initialize(credentials_path:)
    config = YAML.load_file(CONFIG_PATH)
    impersonated_email = config['GMAIL_ADDRESS'] || raise("Missing 'GMAIL_ADDRESS' in #{CONFIG_PATH}")

    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(credentials_path),
      scope: SCOPE
    )

    authorizer.sub = impersonated_email
    authorizer.fetch_access_token!

    @service = Google::Apis::GmailV1::GmailService.new
    @service.authorization = authorizer
  end

  def fetch_matching_messages(query:)
    result = @service.list_user_messages('me', q: query, max_results: 5)
    return [] unless result.messages

    result.messages.map do |msg_meta|
      msg = @service.get_user_message('me', msg_meta.id)
      hheaders = msg.payload.headers.map { |h| [h.name, h.value] }.to_h
      {
        id: msg.id,
        from: headers['From'],
        subject: headers['Subject'],
        snippet: msg.snippet
      }
    end
  end
end


