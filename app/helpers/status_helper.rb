module StatusHelper
  STATUS_MAPPING = {
    'pending' => 'secondary',
    'succeeded' => 'success',
    'failed' => 'danger'
  }.freeze

  def status_badge(status)
    content_tag :span, class: "badge badge-#{STATUS_MAPPING[status]}" do
      t("statuses.#{status}")
    end
  end
end
