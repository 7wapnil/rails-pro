module SettleHelper
  SETTLE_MAPPING = {
    unsettled: 'secondary',
    won: 'success',
    lost: 'danger'
  }.freeze

  def settle_badge(settle)
    content_tag :span, class: "badge badge-#{SETTLE_MAPPING[settle]}" do
      t("settles.#{settle}")
    end
  end
end
