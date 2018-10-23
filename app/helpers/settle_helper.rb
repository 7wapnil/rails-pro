module SettleHelper
  SETTLE_MAPPING = {
    'won' => 'success',
    'lost' => 'danger'
  }.freeze

  def settle_badge(settle)
    return unless SETTLE_MAPPING[settle]

    content_tag :span, class: "badge badge-#{SETTLE_MAPPING[settle]}" do
      t("settles.#{settle}")
    end
  end
end
