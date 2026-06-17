# UUID primary keys are the default for all new tables (iteration 0008). Generated models +
# migrations use `id: :uuid` and uuid references. pgcrypto (gen_random_uuid) is enabled in the
# schema. Existing bigint tables are converted separately — see docs/roadmap/iterations/0008.
Rails.application.config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
