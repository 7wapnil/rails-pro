module AlertHelper
  ALERT_TYPES = {
    notice: :info,
    error: :danger,
    success: :success,
    alert: :warning
  }.freeze

  def alert(message, opts = {})
    type = opts[:type] || :notice

    content_tag(:div, class: "alert alert-#{ALERT_TYPES[type]}") do
      concat message
      concat close_tag
    end
  end

  def alerts_from_flash(payload, type: :notice)
    if payload.is_a?(String)
      alert(payload, type: type)
    elsif payload.is_a?(Array)
      content_tag :div do
        payload.each { |msg| concat alert(msg, type: type) }
      end
    else
      raise TypeError,
            "Payload type not supported: must be either String or Array. #{payload.class} is given." # rubocop:disable Metrics/LineLength
    end
  end

  private

  def close_tag
    content_tag :div, '&times;'.html_safe,
                class: 'close', data: { dismiss: :alert }
  end
end
