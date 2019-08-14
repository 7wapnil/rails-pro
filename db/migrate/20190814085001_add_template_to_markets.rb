# frozen_string_literal: true

class AddTemplateToMarkets < ActiveRecord::Migration[5.2]
  def up
    remove_column :markets, :template_id
    add_reference :markets, :template,
                  references: :market_templates,
                  foreign_key: {
                    to_table: :market_templates,
                    on_delete: :nullify
                  }
  end

  def down
    remove_reference :markets, :template
    add_column :markets, :template_id, :string
  end
end
