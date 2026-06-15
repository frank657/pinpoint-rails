# Deep-copies a content subtree into a target workspace (docs/decisions/0005).
#
# Kept deliberately simple for now:
# - Axis 1 content is deep-copied (new rows in the target workspace).
# - Media is shared BY REFERENCE: forked Videos point at the same Vod / youtube_id (no
#   re-upload). Reference counting (Video#cleanup_orphaned_vod) protects the shared asset.
# - Axis 2 taxonomy (Category/Tag) is NOT carried over yet — forked notes start unlabelled.
# - Axis 3 per-user state (progress) is NEVER copied.
#
# Tenancy: writes run with the TARGET workspace as the current tenant (so new rows land
# there); reads of the SOURCE subtree are wrapped in `read { }` (without_tenant) so they see
# the source's own workspace.
class ForkService
  def self.call(source, target_workspace:, forked_by: nil, include_notes: true)
    new(source, target_workspace, forked_by, include_notes).call
  end

  def initialize(source, target_workspace, forked_by, include_notes)
    @source = source
    @target_workspace = target_workspace
    @forked_by = forked_by
    @include_notes = include_notes
    @video_map = {}
  end

  def call
    target = ActsAsTenant.with_tenant(@target_workspace) do
      ApplicationRecord.transaction { copy(@source) }
    end
    record_attribution(target)
    target
  end

  private

  def read(&) = ActsAsTenant.without_tenant(&)

  def copy(obj)
    case obj
    when Video then copy_video(obj)
    when Note  then copy_note(obj)
    else raise ArgumentError, "Cannot fork #{obj.class}"
    end
  end

  def copy_video(video)
    @video_map[video.id] ||= begin
      new_video = Video.create!(
        source: video.source, title: video.title, duration_seconds: video.duration_seconds,
        youtube_id: video.youtube_id, vod: video.vod, uploaded_by: @forked_by
      )
      if @include_notes
        read { Note.for_video(video).to_a }.each { |n| copy_note(n, new_video) }
        read { Video::Segment.for_video(video).to_a }.each { |s| copy_segment(s, new_video) }
      end
      new_video
    end
  end

  def copy_note(note, video = nil)
    video ||= note.video_id && copy_video(read { note.video })

    new_note = Note.new(
      note_type: note.note_type, title: note.title,
      start_seconds: note.start_seconds, end_seconds: note.end_seconds,
      video: video, created_by: @forked_by
    )
    new_note.body = note.body.to_s if note.body.body.present?
    new_note.save!
    new_note
  end

  def copy_segment(segment, video)
    Video::Segment.create!(video: video, title: segment.title, start_seconds: segment.start_seconds,
                           end_seconds: segment.end_seconds, position: segment.position)
  end

  def record_attribution(target)
    Fork.create!(
      source_type: @source.class.name, source_id: @source.id.to_s,
      source_workspace_id: read { @source.workspace_id },
      target_type: target.class.name, target_id: target.id.to_s,
      target_workspace: @target_workspace, forked_by: @forked_by
    )
  end
end
