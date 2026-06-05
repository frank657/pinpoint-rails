module App
  class TrainingSessionsController < BaseController
    def index
      sessions = TrainingSession.where(user: current_user).recent.includes(:notes)
      render inertia: "training/Index", props: {
        sessions: sessions.map { |s| session_json(s) },
        stats: stats(sessions.to_a)
      }
    end

    def create
      session = TrainingSession.new(session_params)
      session.user = current_user
      session.note_ids = Array(params[:note_ids]).reject(&:blank?) if params[:note_ids]
      session.save!
      redirect_to app_training_sessions_path, notice: "Session logged."
    end

    def destroy
      TrainingSession.where(user: current_user).find(params[:id]).destroy!
      redirect_to app_training_sessions_path
    end

    private

    def session_params
      params.permit(:date, :gi, :kind, :duration_minutes, :location, :partners, :reflection, :intensity)
    end

    def session_json(session)
      {
        id: session.id, date: session.date.iso8601, gi: session.gi, kind: session.kind,
        durationMinutes: session.duration_minutes, location: session.location,
        partners: session.partners, reflection: session.reflection,
        intensity: session.intensity, noteCount: session.notes.size
      }
    end

    def stats(sessions)
      {
        totalSessions: sessions.size,
        totalMinutes: sessions.sum { |s| s.duration_minutes || 0 },
        streak: current_streak(sessions.map(&:date).uniq)
      }
    end

    # Consecutive days with a session, counting back from today (or yesterday).
    def current_streak(dates)
      set = dates.to_set
      day = Date.current
      day -= 1 unless set.include?(day)
      streak = 0
      while set.include?(day)
        streak += 1
        day -= 1
      end
      streak
    end
  end
end
