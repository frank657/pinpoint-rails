namespace :vod do
  desc "Attach cover images from the provider for ready Vods that are missing one"
  task backfill_covers: :environment do
    ready = Vod.where(status: :ready)
    attached = 0
    skipped = 0

    ready.find_each do |vod|
      next if vod.cover_image.attached?

      vod.attach_cover_image_from_provider
      if vod.cover_image.attached?
        attached += 1
        puts "Vod ##{vod.id} (#{vod.key}): cover attached"
      else
        skipped += 1
        puts "Vod ##{vod.id} (#{vod.key}): no cover_url from provider — skipped"
      end
    rescue StandardError => e
      skipped += 1
      puts "Vod ##{vod.id} (#{vod.key}): #{e.class} #{e.message} — skipped"
    end

    puts "Done. #{attached} attached, #{skipped} skipped."
  end
end
