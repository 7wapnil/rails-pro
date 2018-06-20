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
      concat message.html_safe
      concat close_tag
    end
  end

  def flash_message(message, opts = {})
    type = opts[:type] || :notice

    content_tag(:div, '',
                class: 'flash-message',
                data: {
                  type: type,
                  text: message
                })
  end

  def alerts_from_flash(payload, type: :notice)
    if payload.is_a?(String)
      flash_message(payload, type: type)
    elsif payload.is_a?(Array)
      content_tag :div do
        payload.each { |msg| concat flash_message(msg, type: type) }
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
