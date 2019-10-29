# frozen_string_literal: true

module EveryMatrix
  class Table < PlayItem
    has_one :details,
            class_name: EveryMatrix::TableDetails.name,
            foreign_key: :play_item_id
  end
end
