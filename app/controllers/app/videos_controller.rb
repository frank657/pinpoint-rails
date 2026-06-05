module App
  class VideosController < BaseController
    def index
      render inertia: "videos/Index", props: {
        videos: current_workspace_videos.order(created_at: :desc).map { |v| video_json(v) }
      }
    end

    def show
      video = Video.find(params[:id])
      authorize! video, to: :show?
      render inertia: "videos/Show", props: {
        video: video_json(video),
        playback: playback_json(video),
        resumeSeconds: my_progress(video)&.resume_seconds || 0,
        notes: Note.for_video(video).includes(:category, :tags, :rich_text_body).map { |n| note_json(n) },
        segments: Segment.for_video(video).map { |s| segment_json(s) },
        categories: Category.order(:name).map { |c| { id: c.id, name: c.name } },
        tags: Tag.order(:name).pluck(:name),
        transcript: TranscriptLine.for_video(video).map { |l| { startSeconds: l.start_seconds, text: l.text } }
      }
    end

    # AI summary + flashcard drafts from the transcript (docs/decisions/0009). JSON (axios).
    def summary
      video = Video.find(params[:id])
      authorize! video, to: :show?
      source = video.transcript_lines.order(:start_seconds).pluck(:text).join(" ")
      source = video.title if source.blank?
      render json: { summary: Ai.summarize(source), flashcards: Ai.draft_flashcards(source) }
    end

    # Accept an AI flashcard draft (front/back, possibly edited): persist it as a rich-text
    # Note and enroll it in spaced repetition as a Phase 8 review card. This is the bridge
    # from the AI draft (assistive) to durable, user-owned study material (docs/decisions/0009).
    def accept_flashcard
      video = Video.find(params[:id])
      authorize! video, to: :update?
      note = Note.create!(
        note_type: :rich_text,
        title: params[:front].to_s.strip.presence || "Flashcard",
        body: params[:back].to_s,
        created_by: current_user
      )
      ReviewCard.sync_for(note, current_user)
      head :created
    end

    # Inertia flow: paste a YouTube link.
    def create_youtube
      result = Youtube::Ingest.call(params[:url])
      video = Video.create!(
        source: :youtube,
        youtube_id: result.youtube_id,
        title: result.title,
        duration_seconds: result.duration_seconds,
        uploaded_by: current_user
      )
      redirect_to app_video_path(video), notice: "Video added."
    rescue Youtube::Ingest::InvalidUrl => e
      redirect_to app_videos_path, inertia: { errors: { url: e.message } }
    end

    # JSON poll for upload progress (reads DB status set by the Aliyun webhook).
    def status
      video = Video.find(params[:id])
      authorize! video, to: :status?
      render json: { status: video.upload_status, playable: video.playable? }
    end

    def destroy
      video = Video.find(params[:id])
      authorize! video, to: :destroy?
      video.destroy!
      redirect_to app_videos_path, notice: "Video deleted."
    end

    private

    def current_workspace_videos
      Video.all # tenant-scoped to the current workspace by acts_as_tenant
    end

    def video_json(video)
      {
        id: video.id,
        title: video.title,
        source: video.source,
        youtubeId: video.youtube_id,
        durationSeconds: video.duration_seconds,
        status: video.upload_status,
        playable: video.playable?,
        createdAt: video.created_at.iso8601
      }
    end

    def playback_json(video)
      if video.youtube?
        { source: "youtube", youtubeId: video.youtube_id }
      elsif video.vod&.ready?
        { source: "upload", status: "ready", hlsUrl: safe_hls(video.vod) }
      else
        { source: "upload", status: video.upload_status, hlsUrl: nil }
      end
    end

    def safe_hls(vod)
      vod.url("m3u8")
    rescue AliVod::Error
      nil
    end
  end
end
