module AliVod
  # Maps our action names to Aliyun VOD API actions and performs the RPC call, normalising
  # the CamelCase response into snake_case symbol keys.
  module Request
    def self.post(action, params = {})
      ::AliVod.client.request(action: actions[action], params:, opts: post_opts)&.keys_to_snake_case
    rescue => e
      Rails.logger.error("[AliVod] #{action} failed: #{e.message}")
      raise ::AliVod::Error, "#{action} failed: #{e.message}"
    end

    def self.actions
      {
        get_original_video: "GetMezzanineInfo",
        get_video:          "GetPlayInfo",
        get_video_list:     "GetVideoList",
        get_videos_by_ids:  "GetVideoInfos",
        upload_info_url:    "GetURLUploadInfos",
        upload_info_file:   "GetUploadDetails",
        upload_file:        "CreateUploadVideo",
        upload_url:         "UploadMediaByURL",
        upload_data:        "RefreshUploadVideo",
        delete_video:       "DeleteVideo",
        create_category:    "AddCategory",
        get_categories:     "GetCategories",
        delete_category:    "DeleteCategory",
        transcode:          "SubmitTranscodeJobs",
        get_template:       "GetTranscodeTemplateGroup",
        del_streams:        "DeleteStream",
        update_video_info:  "UpdateVideoInfos"
      }
    end

    def self.post_opts
      { method: "POST", format_params: true }
    end
  end
end
