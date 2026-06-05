# AI port (docs/decisions/0009). Swappable provider; defaults to Anthropic Claude when a key
# is configured, otherwise a deterministic Null provider so the feature works offline and in
# tests without secrets. Output is ASSISTIVE — always presented as an editable draft.
module Ai
  module_function

  def provider
    if Rails.application.credentials.dig(:ai, :anthropic_api_key).present?
      Anthropic
    else
      Null
    end
  end

  def summarize(text, **opts) = provider.summarize(text, **opts)
  def draft_flashcards(text, **opts) = provider.draft_flashcards(text, **opts)

  # Automatic speech recognition for an uploaded video. Returns timestamped lines:
  # [{ start_seconds: Float, text: String }, …]. Behind the same provider abstraction so
  # specs stub it and never hit the network (docs/decisions/0009).
  def transcribe(video, **opts) = provider.transcribe(video, **opts)

  # Deterministic offline fallback.
  module Null
    module_function

    def summarize(text, **)
      sentences = text.to_s.split(/(?<=[.!?])\s+/).reject(&:blank?)
      "AI summary (offline draft): " + sentences.first(3).join(" ")
    end

    def draft_flashcards(text, max: 5, **)
      text.to_s.split(/(?<=[.!?])\s+/).reject(&:blank?).first(max).map do |s|
        { front: s.split.first(6).join(" ") + "…?", back: s.strip }
      end
    end

    # Deterministic placeholder transcript so the pipeline is exercisable offline and in
    # tests. A real provider (Aliyun ASR / Whisper) replaces this; the contract is the
    # array-of-lines shape, not the words.
    def transcribe(video, **)
      [
        { start_seconds: 0.0,  text: "Transcript pending for #{video.title}." },
        { start_seconds: 5.0,  text: "Automatic speech recognition has not been configured." }
      ]
    end
  end

  # Real provider — calls Claude when a key is set. Skeleton per ADR 0009; the Null provider
  # is the baseline until the API integration is fleshed out.
  module Anthropic
    module_function

    def summarize(text, **opts) = Null.summarize(text, **opts) # TODO: real Claude call
    def draft_flashcards(text, **opts) = Null.draft_flashcards(text, **opts)
    def transcribe(video, **opts) = Null.transcribe(video, **opts) # TODO: real ASR provider
  end
end
