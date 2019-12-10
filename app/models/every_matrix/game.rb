# frozen_string_literal: true

module EveryMatrix
  class Game < PlayItem
    has_one :details,
            class_name: EveryMatrix::GameDetails.name,
            foreign_key: :play_item_id,
            dependent: :destroy
  end
end
