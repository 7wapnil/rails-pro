class AddOriginToEntries < ActiveRecord::Migration[5.2]
  def change
    add_reference :entries, :origin, polymorphic: true, index: true
  end
end
