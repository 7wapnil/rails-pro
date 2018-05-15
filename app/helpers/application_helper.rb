module ApplicationHelper
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

  private

  def close_tag
    content_tag :div, '&times;'.html_safe,
                class: 'close', data: { dismiss: :alert }
  end
end
