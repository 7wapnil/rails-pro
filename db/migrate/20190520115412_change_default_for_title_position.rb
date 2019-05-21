class ChangeDefaultForTitlePosition < ActiveRecord::Migration[5.2]
  def change
    change_column_default :titles, :position, from: 999, to: 9999
  end
end
