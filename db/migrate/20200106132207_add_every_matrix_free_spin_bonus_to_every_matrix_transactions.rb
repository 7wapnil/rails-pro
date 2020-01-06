# rubocop:disable Metrics/LineLength
class AddEveryMatrixFreeSpinBonusToEveryMatrixTransactions < ActiveRecord::Migration[5.2]
  def change
    add_reference :every_matrix_transactions,
                  :every_matrix_free_spin_bonus,
                  foreign_key: true,
                  index: { name: 'index_transaction_free_spin_bonus_id' }
  end
end
# rubocop:enable Metrics/LineLength
