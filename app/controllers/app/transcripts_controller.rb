module App
  class TranscriptsController < BaseController
    # Import a transcript for a video from pasted text (SRT/VTT or "M:SS text"). YouTube
    # caption fetch + uploaded-video ASR are pluggable provider concerns (Phase 11 notes).
    def create
      video = Video.find(params[:id])
      authorize! video, to: :update?
      lines = Transcript::Parse.call(params[:text])

      ApplicationRecord.transaction do
        video.transcript_lines.delete_all
        lines.each_with_index do |line, i|
          video.transcript_lines.create!(start_seconds: line[:start_seconds], text: line[:text], position: i)
        end
      end
      redirect_to app_video_path(video), notice: "Transcript imported (#{lines.size} lines)."
    end
  end
end
