module App
  class VideosController < BaseController
    def index
      videos = filtered_videos.includes(:tags, :athletes, :notes, vod: { cover_image_attachment: :blob })
      render inertia: "videos/Index", props: {
        videos: videos.map { |v| video_json(v) },
        tags: Tag.order(:name).pluck(:name),
        athletes: Athlete.order(:name).pluck(:name),
        sources: Video.sources.keys,
        filters: {
          q: params[:q], tag: params[:tag], athlete: params[:athlete],
          source: params[:source], addedFrom: params[:added_from], addedTo: params[:added_to]
        }
      }
    end

    def show
      video = Video.find(params[:id])
      authorize! video, to: :show?
      # Reconcile Vod status on every show-page load so a video stuck at "uploading"
      # (webhook-unreachable in dev, or delayed delivery in prod) self-heals on first visit.
      video.vod&.sync_from_provider! if video.upload? && !video.vod&.ready?
      render inertia: "videos/Show", props: {
        video: video_show_json(video),
        playback: playback_json(video),
        resumeSeconds: my_progress(video)&.resume_seconds || 0,
        notes: Note.for_video(video).includes(:categories, :tags, :positions, :techniques, :rich_text_body).map { |n| note_json(n) },
        segments: Video::Segment.for_video(video).map { |s| segment_json(s) },
        categories: Category.order(:name).map { |c| { id: c.id, name: c.name } },
        positions: Position.order(:name).map { |p| { id: p.id, name: p.name } },
        techniques: Technique.order(:name).map { |t| { id: t.id, name: t.name } },
        tags: Tag.order(:name).pluck(:name),
        athletes: Athlete.order(:name).map { |a| athlete_json(a) }
      }
    end

    # Step 2 of the direct-upload flow: create the Video record after the client has confirmed
    # the Vod reached at least "uploaded" via the status poll. We accept the signed_id minted
    # in Vod::DirectUploadsController#create and validate ownership + upload state here.
    def create
      vod = ::Vod.find_signed!(params[:signed_id], purpose: :vod_upload)
      raise ActiveRecord::RecordNotFound unless vod.uploaded_by == current_user
      raise ActionController::BadRequest, "vod not yet uploaded" unless vod.uploaded_to_provider?

      video = Video.create!(
        source:      :upload,
        vod:         vod,
        title:       params[:title].presence || vod.filename,
        uploaded_by: current_user
      )
      render json: { videoId: video.id }, status: :created
    end

    # Inertia flow: paste a YouTube link. Also imports the video's chapters as Segments right away
    # (one per timestamped description line) so the user lands on a pre-segmented timeline. The
    # import is best-effort — a chapter-fetch failure must never block adding the video.
    def create_youtube
      result = Youtube::Ingest.call(params[:url])
      video = Video.create!(
        source: :youtube,
        youtube_id: result.youtube_id,
        title: result.title,
        duration_seconds: result.duration_seconds,
        uploaded_by: current_user
      )
      imported = import_youtube_chapters_safely(video)
      notice = imported.positive? ? "Video added — imported #{imported} #{'segment'.pluralize(imported)} from its chapters." : "Video added."
      redirect_to app_video_path(video), notice: notice
    rescue Youtube::Ingest::InvalidUrl => e
      redirect_to app_videos_path, inertia: { errors: { url: e.message } }
    end

    # Import the chapters YouTube derives from the video description as Segments (one per
    # timestamped line). Idempotent: skips any chapter whose start time already has a segment, so
    # re-running only fills gaps. YouTube-only; needs the Data API key (else 0 chapters found).
    def import_chapters
      video = Video.find(params[:id])
      authorize! video, to: :update?
      return redirect_to(app_video_path(video), alert: "Chapters can only be imported from YouTube videos.") unless video.youtube?

      created = import_youtube_chapters(video)
      notice = created.positive? ? "Imported #{created} #{'segment'.pluralize(created)} from YouTube." : "No chapters found in the YouTube description."
      redirect_to app_video_path(video), notice: notice
    end

    # JSON poll for upload progress. Reconciles against the real Aliyun state on each poll so
    # the video advances past "uploading" even when the webhook can't reach the server (e.g. dev).
    def status
      video = Video.find(params[:id])
      authorize! video, to: :status?
      video.vod&.sync_from_provider! if video.upload? && !video.vod&.ready?
      render json: { status: video.upload_status, playable: video.playable? }
    end

    def update
      video = Video.find(params[:id])
      authorize! video, to: :update?
      video.title = params[:title].to_s.strip.presence || video.title if params.key?(:title)
      video.description = params[:description].to_s if params.key?(:description)
      video.tag_names = name_list(params[:tag_names]) if params.key?(:tag_names)
      video.athlete_names = name_list(params[:athlete_names]) if params.key?(:athlete_names)
      assign_video_taxonomy(video)
      video.save!
      redirect_to app_video_path(video)
    end

    def destroy
      video = Video.find(params[:id])
      authorize! video, to: :destroy?
      video.destroy!
      redirect_to app_videos_path, notice: "Video deleted."
    end

    private

    def filtered_videos
      videos = Video.all
      videos = videos.search(params[:q]) if params[:q].present?
      videos = videos.with_tag(params[:tag]) if params[:tag].present?
      videos = videos.featuring(params[:athlete]) if params[:athlete].present?
      videos = videos.from_source(params[:source]) if Video.sources.key?(params[:source])
      from = parse_date(params[:added_from])&.beginning_of_day
      to   = parse_date(params[:added_to])&.end_of_day
      videos = videos.added_between(from, to) if from || to
      videos.order(created_at: :desc)
    end

    def parse_date(str)
      str.present? ? Date.parse(str) : nil
    rescue ArgumentError
      nil
    end

    # Accept either an array or a comma-separated string of names.
    def name_list(raw)
      raw.is_a?(Array) ? raw : raw.to_s.split(",")
    end

    # Video-level curated taxonomy (iteration 0007 scope addition) — categories, positions and
    # techniques, mirroring the per-note assignment in NotesController#assign_taxonomy.
    def assign_video_taxonomy(video)
      video.categories = Category.where(id: params[:category_ids]) if params.key?(:category_ids)
      video.positions  = Position.where(id: params[:position_ids]) if params.key?(:position_ids)
      video.techniques = Technique.where(id: params[:technique_ids]) if params.key?(:technique_ids)
    end

    # Best-effort wrapper for the create flow: never let a chapter-import hiccup fail the add.
    def import_youtube_chapters_safely(video)
      import_youtube_chapters(video)
    rescue StandardError => e
      Rails.logger.warn("[create_youtube] chapter import failed: #{e.class} #{e.message}")
      0
    end

    # Pull chapters from YouTube and create the ones we don't already have (matched by start
    # time). Returns the number created. Positions continue after any existing segments.
    def import_youtube_chapters(video)
      chapters = Youtube::Chapters.call(video.youtube_id, duration: video.duration_seconds)
      existing = video.segments.pluck(:start_seconds).to_set
      fresh = chapters.reject { |c| existing.include?(c[:start_seconds]) }
      base = (video.segments.maximum(:position) || -1) + 1

      Video::Segment.transaction do
        fresh.each_with_index do |c, i|
          Video::Segment.create!(
            video: video, title: c[:title],
            start_seconds: c[:start_seconds], end_seconds: c[:end_seconds], position: base + i
          )
        end
      end
      fresh.size
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
        poster: video_poster(video),
        noteCount: video.notes.size,
        athletes: video.athletes.map(&:name),
        tags: video.tags.map(&:name),
        createdAt: video.created_at.iso8601
      }
    end

    # The richer payload for the video show page: everything video_json carries, plus the
    # rich-text description, video-level taxonomy and full athlete objects (avatar + initials).
    def video_show_json(video)
      video_json(video).merge(
        description: sanitized_html(video.description),
        segmentCount: video.segments.size,
        categories: video.categories.map { |c| { id: c.id, name: c.name } },
        positions: video.positions.map { |p| { id: p.id, name: p.name } },
        techniques: video.techniques.map { |t| { id: t.id, name: t.name } },
        athletes: video.athletes.map { |a| athlete_json(a) }
      )
    end

    def playback_json(video)
      if video.youtube?
        { source: "youtube", youtubeId: video.youtube_id }
      elsif video.vod&.ready?
        { source: "upload", status: "ready", hlsUrl: safe_hls(video.vod) }
      elsif video.vod&.uploaded?
        # Mezzanine (original file) is playable immediately — don't make the user wait for
        # transcoding. The player uses a native <video> src for this URL (not HLS.js).
        { source: "upload", status: "uploaded", mediaUrl: safe_media(video.vod) }
      else
        { source: "upload", status: video.upload_status, hlsUrl: nil }
      end
    end

    def safe_hls(vod)
      vod.url("m3u8")
    rescue AliVod::Error
      nil
    end

    def safe_media(vod)
      vod.url
    rescue AliVod::Error
      nil
    end
  end
end
