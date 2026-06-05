require "rails_helper"

RSpec.describe "Transcripts, search & AI", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }
  let(:video) { create(:video, workspace: workspace, title: "Closed Guard") }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  it "imports a transcript and finds lines via timestamped search" do
    post transcript_app_video_path(video), params: { text: "0:05 Grip the collar and sleeve\n0:12 Break the posture" }
    expect(video.transcript_lines.count).to eq(2)

    get app_search_path(q: "collar"), headers: inertia_headers
    hits = inertia_props(response)["results"]["transcript"]
    expect(hits.first).to include("videoId" => video.id, "startSeconds" => 5.0)
    expect(hits.first["text"]).to include("collar")
  end

  it "searches notes too" do
    create(:note, workspace: workspace, video: video, title: "Scissor sweep details")
    get app_search_path(q: "scissor"), headers: inertia_headers
    titles = inertia_props(response)["results"]["notes"].map { |n| n["title"] }
    expect(titles).to include("Scissor sweep details")
  end

  it "returns an AI summary and flashcard drafts (offline stub)" do
    post transcript_app_video_path(video), params: { text: "0:01 First idea. 0:05 Second idea. 0:09 Third idea." }
    get summary_app_video_path(video)
    json = JSON.parse(response.body)
    expect(json["summary"]).to include("AI summary")
    expect(json["flashcards"]).to be_an(Array).and be_present
  end

  it "stubs the AI provider in tests (no network)" do
    expect(Ai.provider).to eq(Ai::Null)
  end

  it "accepts an AI flashcard draft into a Note + spaced-repetition card" do
    expect {
      post flashcard_app_video_path(video), params: { front: "Best closed-guard grip?", back: "Collar and sleeve." }
    }.to change(Note, :count).by(1).and change(ReviewCard, :count).by(1)

    note = Note.order(:created_at).last
    expect(note).to be_rich_text
    expect(note.title).to eq("Best closed-guard grip?")
    expect(note.body.to_plain_text).to include("Collar and sleeve")
    expect(ReviewCard.last.user).to eq(user)
  end
end
