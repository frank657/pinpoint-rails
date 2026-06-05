module Webhooks
  # Inbound webhooks are server-to-server (no browser session / CSRF token); they
  # authenticate via provider signatures instead.
  class BaseController < ApplicationController
    skip_forgery_protection
  end
end
