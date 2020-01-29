# frozen_string_literal: true

class AddSlugToTitles < ActiveRecord::Migration[5.2]
  def change
    add_column :titles, :slug, :string, index: true
  end
end
