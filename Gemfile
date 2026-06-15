source "https://rubygems.org"

gem "rails", "~> 8.1.3"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Frontend: Inertia.js + React, bundled with Vite (see docs/decisions/0001)
gem "vite_rails", "~> 3.0"
gem "inertia_rails", "~> 3.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Image processing for Active Storage variants
gem "image_processing", "~> 2.0"
gem "ruby-vips"

# --- Domain stack (ported from method-channel, see docs/decisions/0007) ---

# Authentication (session-based; NO JWT — see docs/decisions/0001)
gem "devise", "~> 4.9"
# Authorization (policy classes — see docs/decisions/0008)
gem "action_policy", "~> 0.7"
# Multi-tenancy scoped to Workspace (see docs/decisions/0002)
gem "acts_as_tenant", "~> 1.0"

# Background jobs
gem "sidekiq", "~> 7.3"
gem "sidekiq-cron"

# Aliyun OSS (Active Storage) + Aliyun VOD (video) — ported in Phase 2
gem "activestorage-aliyun"
gem "aliyun-sdk", require: "aliyun/oss"
gem "aliyunsdkcore"

# Slugs, full-text search, pagination
gem "friendly_id", "~> 5.5"
gem "pg_search"
gem "kaminari"

# Notifications, audit trail, i18n (opted in — see docs/decisions/0007)
gem "noticed", "~> 2.0"
gem "paper_trail"
gem "paper_trail-association_tracking"
gem "mobility", "~> 1.3"

# Utilities
gem "nilify_blanks", "~> 1.4"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Testing
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails"
  gem "shoulda-matchers", "~> 6.0"
  gem "faker"

  # Load env vars from .env
  gem "dotenv-rails"

  # Console niceties
  gem "pry-rails"
  gem "pry-byebug"
  gem "awesome_print"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  # Preview emails in the browser instead of sending
  gem "letter_opener"
  # Detect N+1 queries in development
  gem "prosopite"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
