# acts_as_tenant uses a thread-global current tenant; reset it between examples so leakage
# from one spec never affects the next (docs/decisions/0002).
RSpec.configure do |config|
  config.after { ActsAsTenant.current_tenant = nil }
end
