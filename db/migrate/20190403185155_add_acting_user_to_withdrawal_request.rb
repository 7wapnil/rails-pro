class AddActingUserToWithdrawalRequest < ActiveRecord::Migration[5.2]
  def change
    add_reference :withdrawal_requests, :actioned_by, null: true,
                                                      index: true,
                                                      foreign_key: { to_table: :users }
  end
end
