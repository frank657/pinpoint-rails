# Generates an ASR transcript for an uploaded video once Aliyun reports it `ready`
# (Phase 11). Enqueued from the VOD webhook, which runs without a tenant — so we re-enter
# the video's workspace here before touching tenant-scoped TranscriptLine rows. The AI
# provider is stubbed in tests (docs/decisions/0009); this job never blocks on the network
# in specs.
class TranscribeJob < ApplicationJob
  queue_as :default

  def perform(video_id, workspace_id)
    workspace = Workspace.find_by(id: workspace_id)
    return unless workspace

    ActsAsTenant.with_tenant(workspace) do
      video = Video.find_by(id: video_id)
      return unless video&.upload?
      return if video.transcript_lines.exists? # don't clobber an imported transcript

      lines = Ai.transcribe(video)
      ApplicationRecord.transaction do
        lines.each_with_index do |line, i|
          video.transcript_lines.create!(start_seconds: line[:start_seconds], text: line[:text], position: i)
        end
      end
    end
  end
end
