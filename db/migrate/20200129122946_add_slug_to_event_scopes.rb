# frozen_string_literal: true

class AddSlugToEventScopes < ActiveRecord::Migration[5.2]
  def change
    add_column :event_scopes, :slug, :string, index: true
  end
end
