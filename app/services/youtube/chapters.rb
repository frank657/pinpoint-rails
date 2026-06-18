require "net/http"

# Fetches a YouTube video's description (Data API v3, part=snippet) and parses its timestamp
# lines into chapter entries via Youtube::ChapterParser.
#
# Needs the API key (credentials: youtube.api_key) — the keyless oEmbed endpoint doesn't return
# the description. Without a key, or if the video/description can't be fetched, returns [] so the
# caller can simply report "no chapters found". The network call is an isolated seam (stubbed in
# specs). See docs/SETUP_CREDENTIALS.md.
module Youtube
  class Chapters
    def self.call(youtube_id, duration: nil) = new(youtube_id, duration:).call

    def initialize(youtube_id, duration: nil)
      @youtube_id = youtube_id.to_s
      @duration = duration
    end

    def call
      description = fetch_description
      return [] if description.blank?

      ChapterParser.call(description, duration: @duration)
    end

    private

    def fetch_description
      key = Rails.application.credentials.dig(:youtube, :api_key)
      return nil if key.blank? || @youtube_id.blank?

      body = http_get("https://www.googleapis.com/youtube/v3/videos?part=snippet&id=#{@youtube_id}&key=#{key}")
      body && JSON.parse(body).dig("items", 0, "snippet", "description")
    rescue JSON::ParserError
      nil
    end

    # Isolated network seam — stubbed in specs.
    def http_get(url)
      res = Net::HTTP.get_response(URI(url))
      res.is_a?(Net::HTTPSuccess) ? res.body : nil
    rescue StandardError => e
      Rails.logger.warn("[Youtube::Chapters] GET #{url} failed: #{e.class} #{e.message}")
      nil
    end
  end
end
