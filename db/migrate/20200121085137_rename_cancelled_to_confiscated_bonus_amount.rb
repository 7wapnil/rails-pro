class RenameCancelledToConfiscatedBonusAmount < ActiveRecord::Migration[5.2]
  def change # rubocop:disable Metrics/MethodLength
    rename_column :entry_requests,
                  :cancelled_bonus_amount,
                  :confiscated_bonus_amount
    rename_column :entries,
                  :cancelled_bonus_amount,
                  :confiscated_bonus_amount
    rename_column :entries,
                  :base_currency_cancelled_bonus_amount,
                  :base_currency_confiscated_bonus_amount
    rename_column :entries,
                  :cancelled_bonus_amount_after,
                  :confiscated_bonus_amount_after
    rename_column :wallets,
                  :cancelled_bonus_balance,
                  :confiscated_bonus_balance
  end
end
