### ✅ Final `README.md` (Updated with Labeling, Star, Logging, and Filtering)

# gmail_sms_notifier

A lightweight Ruby tool that monitors your Gmail account and sends an SMS via OpenPhone when new unread emails arrive from specific sender domains (e.g., `state.gov`, `ssa.gov`). Ideal for time-critical alerts that should reach your phone — and your wrist via Apple Watch — without unnecessary noise.

---

## ✅ Features

- Connects to Gmail using a Google Workspace service account
- Filters by sender domains (e.g., `state.gov`, `ssa.gov`)
- Sends SMS alerts using the OpenPhone API
- Designed for crontab use — runs silently in the background
- Marks processed messages as read ✅
- Applies the Gmail label `"SMS Sent"` to matched messages ✅
- Adds a Gmail ⭐️ star to messages that triggered alerts ✅
- Logs all operations with timezone-aware timestamps (Thailand local time) ✅
- Filters out system noise (e.g., Gmail delivery failures) using Gmail search syntax ✅
- Reads config from a YAML file (`.config.yml`)

---

## 🔧 Requirements

- Ruby 3.x
- Bundler
- OpenPhone API access
- Gmail API enabled in Google Cloud
- A Google Workspace service account with **domain-wide delegation**
- The Gmail label `"SMS Sent"` must be manually created once in the UI

---

## 📦 Installation

1. **Clone this repo** (e.g., `/opt/gmail_sms_notifier`)

2. **Install dependencies using Bundler**:

```bash
cd /opt/gmail_sms_notifier
bundle install
````

3. **Create a log directory**:

```bash
mkdir -p ./log
```

4. **Ensure config file exists at**:

```bash
/etc/rails-env/.config.yml
```

---

## 📜 .config.yml Format

```yaml
OPENPHONE_API: "your_openphone_api_key"
OPENPHONE_PHONE_NUMBER_ALERTS: "+15550001111"
OPENPHONE_PHONE_NUMBER: "+15550002222"

GMAIL_CREDENTIALS_PATH: "/etc/rails-env/gmail-credentials.json"
GMAIL_SENDER_KEYWORDS: "state.gov,ssa.gov"
GMAIL_ADDRESS: "your_email@yourdomain.com"
```

---

## 📄 Gemfile

```ruby
source 'https://rubygems.org'

gem 'httparty'
gem 'googleauth'
gem 'google-apis-gmail_v1'
```

---

## 🕹️ Run It Manually

```bash
bundle exec ruby main.rb
```

---

## 🕰️ Cron Job Example

Create a wrapper script at `/usr/local/bin/gmail_sms_check.sh`:

```bash
#!/bin/bash
cd /opt/gmail_sms_notifier
/usr/bin/env bundle exec ruby main.rb >> ./log/gmail_sms_notifier.log 2>&1
```

Make it executable:

```bash
chmod +x /usr/local/bin/gmail_sms_check.sh
```

Add to crontab (every 15 minutes):

```cron
*/15 * * * * /usr/local/bin/gmail_sms_check.sh
```

---

## 🛡️ Gmail API Access Notes

* Enable the Gmail API in Google Cloud Console
* Set up a service account with **domain-wide delegation**
* Authorize the following scopes in your Workspace Admin Console:

  ```
  https://www.googleapis.com/auth/gmail.modify
  https://www.googleapis.com/auth/gmail.labels
  ```

---

## 🏷️ Gmail Label Setup

You must manually create the label `"SMS Sent"` in the Gmail UI once:

1. In Gmail, scroll left sidebar down and click **More > Create new label**
2. Name it exactly: **SMS Sent**
3. Click **Create**

This label will be applied by the script to messages that trigger alerts.

---

## 🪪 License

MIT

```

