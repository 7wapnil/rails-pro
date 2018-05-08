class RemoveAttributesFromEvents < ActiveRecord::Migration[5.2]
  def change
    remove_reference :events, :event, foreign_key: true
    remove_column :events, :kind, :string
  end
end
