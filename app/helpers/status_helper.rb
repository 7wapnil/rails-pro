# frozen_string_literal: true

module StatusHelper
  STATUS_MAPPING = {
    'succeeded' => 'success',
    'active' => 'success',
    'expired' => 'danger',
    'pending' => 'secondary',
    'live' => 'success',
    'offline' => 'secondary',
    'initial' => 'secondary',
    'sent_to_internal_validation' => 'info',
    'validated_internally' => 'info',
    'sent_to_external_validation' => 'info',
    'accepted' => 'success',
    'pending_cancellation' => 'danger',
    'pending_manual_cancellation' => 'danger',
    'cancelled' => 'danger',
    'cancelled_by_system' => 'danger',
    'pending_manual_settlement' => 'warning',
    'settled' => 'info',
    'rejected' => 'danger',
    'failed' => 'danger'
  }.freeze

  def status_badge(status)
    content_tag :span, class: "badge badge-#{STATUS_MAPPING[status]}" do
      t("statuses.#{status}")
    end
  end
end
