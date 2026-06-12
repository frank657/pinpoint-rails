# Deep-copies a content subtree into a target workspace (docs/decisions/0005).
#
# Rules:
# - Axis 1 content is deep-copied (new rows in the target workspace).
# - Media is shared BY REFERENCE: forked Videos point at the same Vod / youtube_id (no
#   re-upload). Reference counting (Video#cleanup_orphaned_vod) protects the shared asset.
# - Axis 2 taxonomy (Category/Tag) is re-pointed: matched-or-created by name in the target.
# - Axis 3 per-user state (progress, review cards) is NEVER copied.
#
# Tenancy: writes run with the TARGET workspace as the current tenant (so new rows land there
# and Tag/Category find-or-create in the target); reads of the SOURCE subtree are wrapped in
# `read { }` (without_tenant) so they see the source's own workspace.
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
    @category_map = {}
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
    when Video    then copy_video(obj)
    when Note     then copy_note(obj)
    when Notebook then copy_notebook(obj)
    else raise ArgumentError, "Cannot fork #{obj.class}"
    end
  end

  def copy_video(video)
    @video_map[video.id] ||= begin
      new_video = Video.create!(
        source: video.source, title: video.title, duration_seconds: video.duration_seconds,
        youtube_id: video.youtube_id, vod: video.vod, transcript: video.transcript,
        uploaded_by: @forked_by
      )
      if @include_notes
        read { Note.for_video(video).to_a }.each { |n| copy_note(n, new_video) }
        read { Segment.for_video(video).to_a }.each { |s| copy_segment(s, new_video) }
      end
      new_video
    end
  end

  def copy_note(note, video = nil)
    video ||= note.video_id && copy_video(read { note.video })
    category = mapped_category(read { note.category })
    tag_names = read { note.tags.map(&:name) }

    new_note = Note.new(
      note_type: note.note_type, title: note.title,
      start_seconds: note.start_seconds, end_seconds: note.end_seconds,
      video: video, category: category, created_by: @forked_by
    )
    new_note.body = note.body.to_s if note.body.body.present?
    new_note.tags = Tag.for_names(tag_names)
    new_note.save!
    new_note
  end

  def copy_segment(segment, video)
    Segment.create!(video: video, title: segment.title, start_seconds: segment.start_seconds,
                    end_seconds: segment.end_seconds, position: segment.position)
  end

  def copy_notebook(notebook)
    chapters = read { notebook.chapters.to_a }
    items = read { notebook.items.includes(:video).to_a }

    new_notebook = Notebook.create!(title: notebook.title, description: notebook.description)
    chapter_map = chapters.each_with_object({}) do |ch, map|
      map[ch.id] = new_notebook.chapters.create!(title: ch.title, position: ch.position)
    end
    items.each do |item|
      new_notebook.items.create!(
        video: copy_video(read { item.video }),
        chapter: item.notebook_chapter_id && chapter_map[item.notebook_chapter_id],
        position: item.position
      )
    end
    new_notebook
  end

  def mapped_category(category)
    return nil unless category

    @category_map[category.id] ||=
      Category.where("lower(name) = ?", category.name.downcase).first_or_create!(name: category.name)
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
