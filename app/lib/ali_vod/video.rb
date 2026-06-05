module AliVod
  # Provider adapter for a single Aliyun VOD video. Knows nothing about domain models.
  class Video
    class << self
      def status(video_id)
        ::AliVod::Request.post(:upload_info_file, { "MediaIds": video_id })
      end

      def get(video_id)
        ::AliVod::Request.post(:get_video, { "VideoId": video_id })
      end

      def destroy(video_id)
        ::AliVod::Request.post(:delete_video, { "VideoIds": video_id })
      end

      # Provisions an upload (returns video_id + Base64 upload_address/upload_auth).
      def create_upload_data(title: nil, file_name: nil, extension: nil, user_data: {},
                             tags: nil, template_group_id: nil, storage_location: nil)
        config = Config.new
        params = build_upload_params(config:, title:, file_name:, extension:, user_data:,
                                     tags:, template_group_id:, storage_location:)
        ::AliVod::Request.post(:upload_file, params)
      end

      private

      def build_upload_params(config:, title:, file_name:, extension:, user_data:, tags:,
                              template_group_id:, storage_location:)
        {
          "TemplateGroupId" => template_group_id.presence || config.video_template,
          "FileName"        => build_file_name(file_name:, extension:),
          "Title"           => build_title(title),
          "UserData"        => ::AliVod.upload_callback_data(user_data),
          "Tags"            => build_tags(tags),
          "StorageLocation" => storage_location.presence || config.storage_location
        }
      end

      def build_title(title)
        title.presence || "Untitled Video #{Time.current.to_i}"
      end

      # FileName is the immutable storage key; deterministic and extension-safe.
      def build_file_name(file_name:, extension:)
        ext  = normalize_extension(extension)
        base = (file_name.presence || SecureRandom.uuid).to_s
        base.downcase.end_with?(".#{ext}") ? base : "#{base}.#{ext}"
      end

      def normalize_extension(extension)
        extension.to_s.delete_prefix(".").presence || "mp4"
      end

      def build_tags(tags)
        tag_list =
          case tags
          when nil    then [ Rails.env ]
          when String then ([ Rails.env ] + tags.split(",")).map(&:strip)
          when Array  then [ Rails.env ] + tags
          else [ Rails.env, tags.to_s ]
          end
        tag_list.compact.uniq.join(",")
      end
    end

    def initialize(video_id, definition = nil)
      @video_id   = video_id
      @definition = definition
    end

    def get
      @video = ::AliVod::Request.post(:get_video, { "VideoId": @video_id, "Definition": @definition })
    end

    def status = ::AliVod::Request.post(:upload_info_file, { "MediaIds": @video_id })

    def upload_success? = status.dig(:upload_details)&.first&.dig(:upload_status) == "UPLOAD_SUCCESS"

    def duration = (@video || get).dig(:video_base, :duration).to_f

    def upload_data = ::AliVod::Request.post(:upload_data, { "VideoId": @video_id })

    def destroy = self.class.destroy(@video_id)
  end
end
