# Reads playback/info for a Vod record from Aliyun VOD.
class VodService::Aliyun::Video
  attr_reader :record

  def initialize(record)
    @record = record
  end

  def original_video
    @original_video ||= ::AliVod::Request.post(:get_original_video, { "VideoId": record.key })
  end

  def status = original_video.dig(:mezzanine, :status)
  def uploaded? = status == "Normal"

  def mezzanine_url
    return unless record.uploaded? || record.ready?

    original_video.dig(:mezzanine, :file_url)
  end

  def video
    return unless record.ready?

    @video ||= ::AliVod::Request.post(:get_video, { "VideoId": record.key })
  end

  def cover_url
    video&.dig(:video_base, :cover_url)
  end

  def urls
    video&.dig(:play_info_list, :play_info)&.sort_by { |v| v[:size] }
         &.map { |v| v.slice(*%i[status size definition duration format play_url height width]) }
  end

  # Calls GetPlayInfo regardless of the DB record status — used for on-demand reconciliation.
  def provider_play_info
    resp = ::AliVod::Request.post(:get_video, { "VideoId": record.key })
    resp&.dig(:play_info_list, :play_info)&.sort_by { |v| v[:size] }
        &.map { |v| v.slice(*%i[status size definition duration format play_url height width]) }
  end

  def transcoded_url(format = "m3u8")
    u = urls&.find do |url|
      if format == "m3u8"
        url[:format] == format && url[:definition] == "AUTO"
      else
        url[:format] == format
      end
    end

    u&.dig(:play_url)
  end

  def url(format = "m3u8")
    if record.ready?
      transcoded_url(format)
    elsif record.uploaded?
      mezzanine_url
    end
  end

  def destroy
    ::AliVod::Request.post(:delete_video, { "VideoIds": record.key })
  end
end
