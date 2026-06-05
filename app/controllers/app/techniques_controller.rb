module App
  class TechniquesController < BaseController
    def create
      Technique.create!(params.permit(:name, :kind, :from_position_id, :to_position_id))
      redirect_to app_positions_path
    end
  end
end
