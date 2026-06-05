require "rails_helper"

RSpec.describe "Authentication", type: :request do
  before { host! "app.lvh.me" }

  describe "sign up" do
    it "creates a user with a default workspace and signs them in" do
      expect {
        post user_registration_path, params: { user: {
          email: "new@example.com", password: "password123", password_confirmation: "password123"
        } }
      }.to change(User, :count).by(1)

      user = User.find_by(email: "new@example.com")
      expect(user.workspaces.pluck(:name)).to eq([ "Personal" ])
      expect(response).to redirect_to(app_root_path)
    end

    it "re-renders with errors on invalid input" do
      post user_registration_path, params: { user: {
        email: "bad", password: "x", password_confirmation: "y"
      } }
      expect(response).to redirect_to(new_user_registration_path)
    end
  end

  describe "sign in / out" do
    let!(:user) { create(:user, email: "me@example.com", password: "password123") }

    it "signs in with valid credentials" do
      post user_session_path, params: { user: { email: "me@example.com", password: "password123" } }
      expect(response).to redirect_to(app_root_path)
    end

    it "rejects invalid credentials" do
      post user_session_path, params: { user: { email: "me@example.com", password: "wrong" } }
      expect(response).not_to redirect_to(app_root_path)
    end

    it "signs out" do
      sign_in user
      delete destroy_user_session_path
      get app_root_path
      # After sign-out the dashboard redirects to sign-in.
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "the dashboard requires authentication" do
    it "redirects anonymous users to sign in" do
      get app_root_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
