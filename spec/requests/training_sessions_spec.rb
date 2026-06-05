require "rails_helper"

RSpec.describe "Training sessions", type: :request do
  let(:user) { create(:user) }
  let(:workspace) { user.workspaces.first }

  before do
    host! "app.lvh.me"
    sign_in user
    ActsAsTenant.current_tenant = workspace
  end

  it "logs a session linked to a note" do
    video = create(:video, workspace: workspace)
    note = create(:note, workspace: workspace, video: video)

    expect {
      post app_training_sessions_path, params: {
        date: Date.current.iso8601, gi: true, kind: "roll", duration_minutes: 60,
        partners: "Alex, Sam", reflection: "Worked back attacks", note_ids: [ note.id ]
      }
    }.to change(TrainingSession, :count).by(1)

    session = TrainingSession.last
    expect(session.user).to eq(user)
    expect(session.kind).to eq("roll")
    expect(session.notes).to include(note)
  end

  it "shows sessions with stats and a streak" do
    TrainingSession.create!(user: user, workspace: workspace, date: Date.current, kind: :drill, duration_minutes: 30)
    TrainingSession.create!(user: user, workspace: workspace, date: Date.current - 1, kind: :roll, duration_minutes: 45)

    get app_training_sessions_path, headers: inertia_headers
    stats = inertia_props(response)["stats"]
    expect(stats["totalSessions"]).to eq(2)
    expect(stats["totalMinutes"]).to eq(75)
    expect(stats["streak"]).to eq(2)
  end

  it "keeps sessions private per user (Axis 3)" do
    TrainingSession.create!(user: user, workspace: workspace, date: Date.current, kind: :drill)
    expect(TrainingSession.where(user: create(:user)).count).to eq(0)
  end
end
