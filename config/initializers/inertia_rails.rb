# frozen_string_literal: true

InertiaRails.configure do |config|
  config.version = ViteRuby.digest
  # History encryption needs the Web Crypto API, which requires a secure context. Dev runs on
  # http://*.lvh.me (not localhost), where it's unavailable — so enable it only outside dev.
  config.encrypt_history = !Rails.env.development?
  config.always_include_errors_hash = true
  config.use_script_element_for_initial_page = true
  config.use_data_inertia_head_attribute = true
end
