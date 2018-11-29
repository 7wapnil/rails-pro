class CreateComments < ActiveRecord::Migration[5.2]
  def change
    create_table :comments do |t|
      t.text :text
      t.belongs_to :commentable, polymorphic: true
      t.belongs_to :user

      t.timestamps
    end

    add_index :comments, %i[commentable_id commentable_type]
  end
end
