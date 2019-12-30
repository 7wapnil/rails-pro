# frozen_string_literal: true

module EveryMatrix
  class VendorPlayItemsController < ApplicationController
    def show
      @play_items =
        EveryMatrix::PlayItem
          .includes(:game_details)
          .where(
            every_matrix_vendor_id: params.require(:id),
            every_matrix_game_details: {
              free_spin_bonus_supported: true
            }
          )
          .order(:name)

      render layout: false
    end
  end
end
