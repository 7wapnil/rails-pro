# frozen_string_literal: true

module StatusHelper
  STATUS_MAPPING = {
    'accepted' => 'success',
    'active' => 'success',
    'cancelled' => 'danger',
    'cancelled_by_system' => 'danger',
    'expired' => 'danger',
    'failed' => 'danger',
    'initial' => 'secondary',
    'pending' => 'secondary',
    'rejected' => 'danger',
    'sent_to_external_validation' => 'info',
    'sent_to_internal_validation' => 'info',
    'settled' => 'info',
    'succeeded' => 'success',
    'validated_internally' => 'info',
    'live' => 'success',
    'offline' => 'secondary'
  }.freeze

  def status_badge(status)
    content_tag :span, class: "badge badge-#{STATUS_MAPPING[status]}" do
      t("statuses.#{status}")
    end
  end
end
