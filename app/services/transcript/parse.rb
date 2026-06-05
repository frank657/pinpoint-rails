# Parses pasted transcript text into timestamped lines. Supports SRT/VTT cue blocks
# (HH:MM:SS,mmm --> ...) and plain "M:SS text" lines. Returns [{ start_seconds:, text: }].
module Transcript
  class Parse
    ARROW = /-->/
    TS    = /(?:\d{1,2}:)?\d{1,2}:\d{2}(?:[.,]\d{1,3})?/

    def self.call(raw)
      text = raw.to_s.strip
      return [] if text.empty?

      text.match?(ARROW) ? parse_cues(text) : parse_plain(text)
    end

    def self.parse_cues(text)
      text.split(/\n\s*\n/).filter_map do |block|
        lines = block.strip.lines.map(&:strip).reject { |l| l.match?(/\A\d+\z/) || l == "WEBVTT" }
        cue = lines.find { |l| l.match?(ARROW) }
        next unless cue

        start = cue[/\A(#{TS})/, 1]
        body = lines.reject { |l| l.match?(ARROW) }.join(" ").strip
        { start_seconds: to_seconds(start), text: body } if start && body.present?
      end
    end

    def self.parse_plain(text)
      text.lines.filter_map do |line|
        if line =~ /\A\s*(#{TS})\s+(.+)/
          { start_seconds: to_seconds(Regexp.last_match(1)), text: Regexp.last_match(2).strip }
        end
      end
    end

    def self.to_seconds(str)
      str.tr(",", ".").split(":").map(&:to_f).reduce(0.0) { |acc, part| acc * 60 + part }
    end
  end
end
