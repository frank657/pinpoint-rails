# Cloze deletion parsing for spaced-repetition cards (docs/decisions/0004, Phase 8).
# Authors mark deletions in a note with Anki-style syntax: `{{c1::answer}}` or
# `{{c1::answer::hint}}`. Each distinct cloze number becomes its OWN review card, so one
# note with `c1` and `c2` yields two cards. Numbers may repeat (the same `c1` twice hides
# both blanks on the same card).
module Cloze
  # c<number> :: answer [ :: optional hint ]
  PATTERN = /\{\{c(\d+)::(.*?)(?:::(.*?))?\}\}/m

  module_function

  # The distinct, sorted cloze indices present in `text` (e.g. [1, 2]).
  def deletions(text)
    text.to_s.scan(/\{\{c(\d+)::/).flatten.map(&:to_i).uniq.sort
  end

  def cloze?(text) = deletions(text).any?

  # Render `text` for the card whose active deletion is `active`. The active deletion is
  # blanked (front) or highlighted (back); every other deletion is shown as plain answer
  # text so the surrounding context reads naturally.
  def render(text, active:, reveal:)
    text.to_s.gsub(PATTERN) do
      idx = ::Regexp.last_match(1).to_i
      answer = ::Regexp.last_match(2)
      hint = ::Regexp.last_match(3)
      if idx == active
        reveal ? %(<mark>#{answer}</mark>) : %([#{hint.presence || "..."}])
      else
        answer
      end
    end
  end
end
