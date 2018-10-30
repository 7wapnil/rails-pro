class ChangeTitlesDefaultKind < ActiveRecord::Migration[5.2]
  def change
    change_column_default :titles, :kind, from: 0, to: nil
  end
end
