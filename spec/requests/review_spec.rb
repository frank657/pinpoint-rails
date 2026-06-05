require "rails_helper"

RSpec.describe "Spaced repetition review", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }
  let(:video) { create(:video, workspace: workspace) }
  let(:note) { create(:note, workspace: workspace, video: video, title: "Grip first") }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  it "adds a note to review (Note ≠ Card)" do
    expect {
      post app_review_cards_path, params: { note_id: note.id }
    }.to change(ReviewCard, :count).by(1)
    card = ReviewCard.last
    expect(card.user).to eq(user)
    expect(card.note).to eq(note)
  end

  it "shows due cards in the queue" do
    ReviewCard.create!(user: user, note: note)
    get "/review", headers: inertia_headers
    expect(inertia_props(response)["cards"].map { |c| c["noteTitle"] }).to include("Grip first")
  end

  it "grades a card and reschedules it into the future" do
    card = ReviewCard.create!(user: user, note: note)
    post app_grade_review_card_path(card), params: { rating: 3 }
    expect(response).to have_http_status(:no_content)
    expect(card.reload.due_at).to be > Time.current
    expect(card.reps).to eq(1)
  end

  it "keeps review state per-user — a shared note is reviewed independently (Axis 3)" do
    ReviewCard.create!(user: user, note: note)
    other = create(:user)
    expect(ReviewCard.where(user: other).count).to eq(0)
    expect(note.reload).not_to respond_to(:due_at) # no scheduling state on the Note
  end

  it "yields one card per cloze deletion (a two-deletion note → two cards)" do
    cloze = create(:note, :rich_text, workspace: workspace,
      title: "Closed guard", body: "Control the {{c1::collar}} and the {{c2::sleeve}}.")
    expect {
      post app_review_cards_path, params: { note_id: cloze.id }
    }.to change(ReviewCard, :count).by(2)
    templates = ReviewCard.where(note: cloze).pluck(:card_template).sort
    expect(templates).to eq(%w[cloze:1 cloze:2])
  end

  it "blanks only the active deletion on a cloze card's front, reveals it on the back" do
    cloze = create(:note, :rich_text, workspace: workspace,
      title: "Guard", body: "The {{c1::collar}} grip and the {{c2::sleeve}} grip.")
    post app_review_cards_path, params: { note_id: cloze.id }
    card = ReviewCard.find_by(note: cloze, card_template: "cloze:1")
    front, back = card.faces
    expect(front).to include("[...]").and include("sleeve")   # c1 hidden, c2 shown as context
    expect(front).not_to include("collar")
    expect(back).to include("collar")
  end

  it "filters the queue to a single theme (category)" do
    guard = create(:category, workspace: workspace, name: "Guard")
    mount = create(:category, workspace: workspace, name: "Mount")
    guard_note = create(:note, workspace: workspace, video: video, title: "Guard note", category: guard)
    mount_note = create(:note, workspace: workspace, video: video, title: "Mount note", category: mount)
    ReviewCard.create!(user: user, note: guard_note)
    ReviewCard.create!(user: user, note: mount_note)

    get "/review", params: { theme: "category:#{guard.id}" }, headers: inertia_headers
    titles = inertia_props(response)["cards"].map { |c| c["noteTitle"] }
    expect(titles).to include("Guard note")
    expect(titles).not_to include("Mount note")
  end
end
