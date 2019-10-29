class AddReferencesToEveryMatrixPlayItem < ActiveRecord::Migration[5.2]
  def change
    add_reference :every_matrix_play_items,
                  :every_matrix_vendor,
                  foreign_key: true,
                  index: {
                    name: :index_play_items_on_vendors_id
                  }
    add_reference :every_matrix_play_items,
                  :every_matrix_content_provider,
                  foreign_key: true,
                  index: {
                    name: :index_play_items_on_content_providers_id
                  }
  end
end
