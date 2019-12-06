# frozen_string_literal: true

module EveryMatrix
  module TransactionsStatusHelper
    TYPE_MAPPING = {
      'Result' => 'success',
      'Wager' => 'danger',
      'Rollback' => 'secondary'
    }.freeze

    def settle_type(status)
      content_tag :span, class: "badge badge-#{TYPE_MAPPING[status]}" do
        t("settles.#{status}")
      end
    end
  end
end
