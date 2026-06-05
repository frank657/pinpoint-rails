module App
  class ForksController < BaseController
    # "Save to my workspace": deep-copy the shared object into the current workspace.
    def create
      share = ActsAsTenant.without_tenant { Share.find_by!(token: params[:token]) }
      source = ActsAsTenant.without_tenant { share.shareable }
      target = ForkService.call(source, target_workspace: current_workspace, forked_by: current_user)
      redirect_to content_path(target), notice: "Saved to your workspace."
    end

    private

    def content_path(obj)
      case obj
      when Course      then app_course_path(obj)
      when Curriculum  then app_curriculum_path(obj)
      when Video       then app_video_path(obj)
      when Folder      then app_folders_path
      when Note        then app_notes_path
      else app_root_path
      end
    end
  end
end
