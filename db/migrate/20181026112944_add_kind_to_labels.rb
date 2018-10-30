class AddKindToLabels < ActiveRecord::Migration[5.2]
  def change
    add_column :labels, :kind, :integer, default: 0
  end
end
