require "net/http"

# Turns a pasted YouTube URL into the data we need for a Video (docs/roadmap/phases/phase-2).
#
# - Parsing the video id is pure/offline.
# - Title + thumbnail come from YouTube's oEmbed endpoint (NO API key needed).
# - Duration needs the YouTube Data API, which requires an API key
#   (credentials: youtube.api_key). Without it, duration is left nil (the player reports it
#   client-side). See docs/SETUP_CREDENTIALS.md.
module Youtube
  class Ingest
    Result = Data.define(:youtube_id, :title, :duration_seconds, :thumbnail_url)

    class InvalidUrl < StandardError; end

    ID = /[\w-]{11}/

    PATTERNS = [
      %r{youtu\.be/(#{ID})},
      %r{youtube\.com/watch\?(?:.*&)?v=(#{ID})},
      %r{youtube\.com/shorts/(#{ID})},
      %r{youtube\.com/embed/(#{ID})},
      %r{youtube\.com/live/(#{ID})}
    ].freeze

    def self.call(url) = new(url).call

    # Pure: extract the 11-char video id from any common YouTube URL form (or a bare id).
    def self.extract_id(url)
      url = url.to_s.strip
      PATTERNS.each { |re| return Regexp.last_match(1) if url.match?(re) && url =~ re }
      return url if url.match?(/\A#{ID}\z/)

      nil
    end

    def initialize(url)
      @url = url.to_s.strip
    end

    def call
      id = self.class.extract_id(@url)
      raise InvalidUrl, "Doesn't look like a YouTube link" unless id

      meta = oembed(id)
      Result.new(
        youtube_id: id,
        title: meta[:title].presence || "YouTube video #{id}",
        duration_seconds: data_api_duration(id),
        thumbnail_url: meta[:thumbnail_url]
      )
    end

    private

    def oembed(id)
      watch_url = "https://www.youtube.com/watch?v=#{id}"
      body = http_get("https://www.youtube.com/oembed?url=#{CGI.escape(watch_url)}&format=json")
      body ? JSON.parse(body).symbolize_keys : {}
    rescue JSON::ParserError
      {}
    end

    def data_api_duration(id)
      key = Rails.application.credentials.dig(:youtube, :api_key)
      return nil if key.blank?

      body = http_get("https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=#{id}&key=#{key}")
      iso = body && JSON.parse(body).dig("items", 0, "contentDetails", "duration")
      iso ? ActiveSupport::Duration.parse(iso).to_i : nil
    rescue JSON::ParserError, ActiveSupport::Duration::ISO8601Parser::ParsingError
      nil
    end

    # Isolated network seam — stubbed in specs.
    def http_get(url)
      res = Net::HTTP.get_response(URI(url))
      res.is_a?(Net::HTTPSuccess) ? res.body : nil
    rescue StandardError => e
      Rails.logger.warn("[Youtube::Ingest] GET #{url} failed: #{e.class} #{e.message}")
      nil
    end
  end
end
