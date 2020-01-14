# frozen_string_literal: true

module EveryMatrix
  class GameRound < ApplicationRecord
    self.table_name = :every_matrix_game_rounds

    include StateMachines::GameRoundStateMachine

    has_many :transactions,
             class_name: EveryMatrix::Transaction.name,
             foreign_key: :round_id
    has_one :wager,
            class_name: EveryMatrix::Wager.name,
            foreign_key: :round_id
    has_one :result,
            class_name: EveryMatrix::Result.name,
            foreign_key: :round_id
    has_one :rollback,
            class_name: EveryMatrix::Rollback.name,
            foreign_key: :round_id
    has_one :customer_bonus, through: :wager
  end
end
