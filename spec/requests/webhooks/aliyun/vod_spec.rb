require "rails_helper"

RSpec.describe "Aliyun VOD webhook", type: :request do
  include ActiveJob::TestHelper

  before do
    host! "app.lvh.me"
    stub_aliyun!
    ActiveJob::Base.queue_adapter = :test
  end

  let(:vod) { create(:vod) }
  let(:webhook_url) { "http://app.lvh.me/webhooks/aliyun/vod" }

  def post_webhook(payload, signature: nil, timestamp: "12345")
    auth = Rails.application.credentials.dig(:aliyun, :vod, :callback_auth)
    sig = signature || Digest::MD5.hexdigest([ webhook_url, timestamp, auth ].join("|"))
    post "/webhooks/aliyun/vod", params: payload,
      headers: { "X-VOD-TIMESTAMP" => timestamp, "X-VOD-SIGNATURE" => sig }
  end

  def extend_json = { app: "pinpoint" }.to_json

  it "marks the vod uploaded on FileUploadComplete" do
    post_webhook({ "EventType" => "FileUploadComplete", "VideoId" => vod.key, "Extend" => extend_json })
    expect(response).to have_http_status(:ok)
    expect(vod.reload).to be_uploaded
  end

  it "marks the vod ready with duration on TranscodeComplete" do
    post_webhook({
      "EventType" => "TranscodeComplete", "VideoId" => vod.key, "Extend" => extend_json,
      "StreamInfos" => [ { "Duration" => "61.5" } ]
    })
    expect(response).to have_http_status(:ok)
    expect(vod.reload).to be_ready
    expect(vod.duration).to eq(61.5)
  end

  it "enqueues ASR transcription for uploaded videos backed by the ready vod" do
    workspace = create(:workspace)
    video = ActsAsTenant.with_tenant(workspace) do
      create(:video, source: :upload, youtube_id: nil, vod: vod, workspace: workspace)
    end

    expect {
      post_webhook({
        "EventType" => "TranscodeComplete", "VideoId" => vod.key, "Extend" => extend_json,
        "StreamInfos" => [ { "Duration" => "61.5" } ]
      })
    }.to have_enqueued_job(TranscribeJob).with(video.id, workspace.id)
  end

  it "rejects an invalid signature" do
    post_webhook({ "EventType" => "FileUploadComplete", "VideoId" => vod.key, "Extend" => extend_json },
                 signature: "wrong")
    expect(response).to have_http_status(:forbidden)
    expect(vod.reload).to be_uploading
  end

  it "ignores callbacks from other apps" do
    post_webhook({ "EventType" => "FileUploadComplete", "VideoId" => vod.key,
                   "Extend" => { app: "someone-else" }.to_json })
    expect(response).to have_http_status(:ok)
    expect(vod.reload).to be_uploading
  end
end
