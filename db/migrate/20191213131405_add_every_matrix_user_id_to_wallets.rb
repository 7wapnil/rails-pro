class AddEveryMatrixUserIdToWallets < ActiveRecord::Migration[5.2]
  def change
    add_column :wallets, :every_matrix_user_id, :string
  end
end
