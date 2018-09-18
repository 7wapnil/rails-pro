class AddAuthorizedAtToEntry < ActiveRecord::Migration[5.2]
  def change
    add_column :entries, :authorized_at, :timestamp
  end
end
