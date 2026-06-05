# A spaced-repetition card for a Note, scheduled with FSRS. Per-user state (Axis 3,
# docs/decisions/0004): a shared Note is reviewed independently by each user; never copied
# on fork.
class ReviewCard < ApplicationRecord
  belongs_to :user
  belongs_to :note

  enum :state, { new: 0, learning: 1, review: 2, relearning: 3 }, prefix: :state

  scope :due, ->(at = Time.current) { where("due_at IS NULL OR due_at <= ?", at) }

  # The card template(s) a note should produce: one card per cloze deletion, otherwise a
  # single "basic" front/back card (Phase 8). A note with `{{c1::…}}` and `{{c2::…}}` yields
  # `["cloze:1", "cloze:2"]`.
  def self.templates_for(note)
    text = [ note.title, note.body.to_plain_text ].compact.join(" ")
    indices = Cloze.deletions(text)
    indices.any? ? indices.map { |i| "cloze:#{i}" } : [ "basic" ]
  end

  # Create every card this note implies for `user`; returns the cards. Idempotent via the
  # unique (user, note, card_template) index.
  def self.sync_for(note, user)
    templates_for(note).map do |template|
      find_or_create_by!(user: user, note: note, card_template: template)
    end
  end

  # The active cloze index for a cloze card, else nil.
  def cloze_index
    Integer(card_template.split(":", 2).last) if card_template.start_with?("cloze:")
  end

  # The front (prompt) and back (answer) HTML for this card, honoring its template.
  def faces
    html = note.body.to_s
    if (idx = cloze_index)
      [ Cloze.render(html, active: idx, reveal: false), Cloze.render(html, active: idx, reveal: true) ]
    else
      [ "", html ]
    end
  end

  # Apply a grade (1=again, 2=hard, 3=good, 4=easy) and reschedule.
  def grade!(rating, now: Time.current)
    update!(Fsrs.schedule(self, rating.to_i, now: now))
  end
end
