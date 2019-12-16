# frozen_string_literal: true

module EveryMatrix
  class FreeSpinBonusesController < ApplicationController
    find :free_spin_bonus,
         only: %i[show],
         class: EveryMatrix::FreeSpinBonus,
         eager_load: {
           free_spin_bonus_wallets: {
             wallet: %i[customer currency]
           },
           free_spin_bonus_play_items: :play_item
         }

    find :free_spin_bonus_wallet,
         only: %i[wallet],
         class: EveryMatrix::FreeSpinBonusWallet,
         eager_load: { wallet: :customer }

    protect_from_forgery except: :play_items_by_vendor

    def index
      @filter = EveryMatrix::FreeSpinBonusesFilter.new(
        query_params: query_params(:free_spin_bonuses),
        page: params[:page]
      )
    end

    def new
      @available_vendors =
        EveryMatrix::Vendor
        .includes(play_items: :game_details)
        .where(
          play_items: {
            every_matrix_game_details: {
              free_spin_bonus_supported: true
            }
          }
        )
        .order(:name)
      @free_spin_bonus = EveryMatrix::FreeSpinBonus.new
    end

    def play_items_by_vendor
      @play_items =
        EveryMatrix::PlayItem
        .includes(:game_details)
        .where(
          every_matrix_vendor_id: params.require(:vendor_id),
          every_matrix_game_details: {
            free_spin_bonus_supported: true
          }
        )
        .order(:name)

      respond_to do |format|
        format.js
      end
    end

    def create
      requested_number = EveryMatrix::FreeSpinBonuses::CreateService.call(
        bonus_params:  bonus_params.to_h,
        play_item_ids: play_item_ids,
        customers_csv: params[:customers_csv]
      )

      redirect_to(
        every_matrix_free_spin_bonuses_path,
        flash: {
          notice: t('bonus_award_requested', number: requested_number)
        }
      )
    end

    def destroy
      requested_number = EveryMatrix::FreeSpinBonuses::ForfeitService.call(
        free_spin_bonus_id: params.require(:id)
      )

      redirect_to(
        every_matrix_free_spin_bonuses_path,
        flash: {
          notice: t('bonus_forfeit_requested', number: requested_number)
        }
      )
    end

    def wallet; end

    private

    def bonus_params
      params
        .require(:every_matrix_free_spin_bonus)
        .permit(
          :every_matrix_vendor_id,
          :number_of_free_rounds,
          :free_rounds_end_date,
          :additional_parameters
        )
    end

    def play_item_ids
      params.require(:play_item_ids)
    end
  end
end
