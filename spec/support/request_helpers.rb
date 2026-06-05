module RequestHelpers
  # Headers that make Rails return the Inertia JSON page object (component + props)
  # instead of the full HTML layout — keeps specs independent of a Vite build.
  def inertia_headers(extra = {})
    { "X-Inertia" => "true", "X-Inertia-Version" => ViteRuby.digest }.merge(extra)
  end

  def inertia_props(response)
    JSON.parse(response.body).fetch("props")
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :request
end
