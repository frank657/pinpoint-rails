module App
  # Athletes are an Axis-2 taxonomy of the people featured in videos (ADR 0004). This surface
  # lists them, lets you add one, and shows every video featuring a given athlete.
  class AthletesController < BaseController
    def index
      render inertia: "athletes/Index", props: {
        athletes: Athlete.order(:name).map { |a| { id: a.id, name: a.name, videoCount: a.videos.size } }
      }
    end

    def show
      athlete = Athlete.find(params[:id])
      authorize! athlete, to: :show?
      render inertia: "athletes/Show", props: {
        athlete: { id: athlete.id, name: athlete.name },
        videos: athlete.videos.includes(:vod).order(created_at: :desc).map { |v| video_card_json(v) }
      }
    end

    def create
      Athlete.create!(name: params[:name])
      redirect_to app_athletes_path, notice: "Athlete added."
    end
  end
end
