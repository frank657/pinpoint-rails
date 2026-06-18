# Parses the timestamp lines out of a YouTube video *description* into chapter entries we can
# turn into Video::Segments. YouTube has no structured "chapters" API — it derives the chapter
# pills from these very lines, so we parse the same text ourselves.
#
# Pure and offline: text in, array of {title:, start_seconds:, end_seconds:} out. The network
# fetch lives in Youtube::Chapters. Each chapter's end is the next chapter's start (closed
# ranges, which is what Note adoption wants — ADR 0011); the last chapter ends at the video
# duration if known, else open-ended (nil).
module Youtube
  class ChapterParser
    # A timestamp at the start of a line: optional bullet/dash, then MM:SS or H:MM:SS (or HH:MM:SS).
    # Captures hours (optional), minutes, seconds, and the trailing label.
    LINE = /\A\s*[-•*]?\s*(?:(\d{1,2}):)?(\d{1,2}):(\d{2})(.*)\z/

    def self.call(text, duration: nil) = new(text, duration:).call

    def initialize(text, duration: nil)
      @text = text.to_s
      @duration = duration
    end

    def call
      entries = parse_lines
      return [] if entries.empty?

      with_end_seconds(entries)
    end

    private

    # One pass over the lines, keeping those that begin with a timestamp. De-duped by start time
    # (first label wins) and sorted, so out-of-order or repeated stamps can't produce bad ranges.
    def parse_lines
      seen = {}
      @text.each_line do |line|
        m = LINE.match(line.chomp) or next
        seconds = (m[1].to_i * 3600) + (m[2].to_i * 60) + m[3].to_i
        seen[seconds] ||= clean_title(m[4])
      end
      seen.sort_by(&:first).map { |secs, title| { title:, start_seconds: secs.to_f } }
    end

    # Strip the separators that sit between the timestamp and the label (": ", " - ", ") ", ".").
    def clean_title(raw)
      title = raw.to_s.sub(/\A[\s:.\-)|–—]+/, "").strip
      title.presence
    end

    def with_end_seconds(entries)
      entries.each_with_index.map do |entry, i|
        nxt = entries[i + 1]
        end_seconds = nxt ? nxt[:start_seconds] : last_end(entry)
        entry.merge(end_seconds:)
      end
    end

    # The final chapter runs to the video's end when we know the duration and it's actually after
    # the chapter start; otherwise it stays open-ended.
    def last_end(entry)
      return nil if @duration.blank?

      @duration.to_f > entry[:start_seconds] ? @duration.to_f : nil
    end
  end
end
