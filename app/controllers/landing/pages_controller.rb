module Landing
  class PagesController < ApplicationController
    def home
      render inertia: "Landing"
    end
  end
end
