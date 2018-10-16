module OutcomeHelper
  TYPE_MAPPING = {
    nil => 'pending',
    true => 'won',
    false => 'lost'
  }.freeze

  OUTCOME_MAPPING = {
    'pending' => 'secondary',
    'won' => 'success',
    'lost' => 'danger'
  }.freeze

  def outcome_badge(outcome)
    type = TYPE_MAPPING[outcome]
    content_tag :span, class: "badge badge-#{OUTCOME_MAPPING[type]}" do
      t("outcomes.#{type}")
    end
  end
end
