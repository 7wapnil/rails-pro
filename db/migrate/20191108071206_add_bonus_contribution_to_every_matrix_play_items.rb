class AddBonusContributionToEveryMatrixPlayItems < ActiveRecord::Migration[5.2]
  def change
    add_column :every_matrix_play_items, :bonus_contribution,
               :decimal, null: false, default: 1
  end
end
