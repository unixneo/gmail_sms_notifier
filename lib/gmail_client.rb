require 'google/apis/gmail_v1'
require 'googleauth'

class GmailClient
  APPLICATION_NAME = 'Gmail SMS Notifier'
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY

  def initialize(credentials_path:)
    # Load service account credentials from JSON file
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(credentials_path),
      scope: SCOPE
    )

    # Domain-wide delegation: impersonate a Workspace user
    authorizer.sub = 'tim@unix.com'
    authorizer.fetch_access_token!

    # Set up Gmail service
    @service = Google::Apis::GmailV1::GmailService.new
    @service.authorization = authorizer
  end

  def fetch_matching_messages(query:)
    result = @service.list_user_messages('me', q: query, max_results: 5)
    return [] unless result.messages

    result.messages.map do |msg_meta|
      msg = @service.get_user_message('me', msg_meta.id)
      headers = msg.payload.headers.map { |h| [h.name, h.value] }.to_h
      {
        id: msg.id,
        from: headers['From'],
        subject: headers['Subject'],
        snippet: msg.snippet
      }
    end
  end
end

