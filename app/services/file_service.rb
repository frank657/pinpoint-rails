require "open-uri"

# Thin helper for attaching files/remote URLs to Active Storage (ported from method-channel).
class FileService
  def self.attach(attached_instance, file)
    attached_instance.attach(file)
  end

  def self.attach_url(attached_instance, url)
    uri = URI.parse(url)
    attached_instance.attach(io: uri.open, filename: File.basename(uri.path))
  end
end
