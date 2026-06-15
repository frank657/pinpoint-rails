module App
  class ProgressController < BaseController
    TRACKABLE_TYPES = %w[Video].freeze

    # Upsert the current user's progress on a trackable (called by the player + completion
    # toggles). Returns 204 — driven by axios, not an Inertia visit.
    def upsert
      raise ActiveRecord::RecordNotFound unless TRACKABLE_TYPES.include?(params[:trackable_type])

      progress = Progress.find_or_initialize_by(
        user: current_user, workspace: current_workspace,
        trackable_type: params[:trackable_type], trackable_id: params[:trackable_id]
      )
      progress.resume_seconds = params[:resume_seconds] if params[:resume_seconds].present?
      if params.key?(:completed)
        completed = ActiveModel::Type::Boolean.new.cast(params[:completed])
        progress.completed_at = completed ? Time.current : nil
      end
      progress.last_viewed_at = Time.current
      progress.save!
      head :no_content
    end
  end
end
