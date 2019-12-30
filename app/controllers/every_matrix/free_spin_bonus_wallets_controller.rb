# frozen_string_literal: true

module EveryMatrix
  class FreeSpinBonusWalletsController < ApplicationController
    find :free_spin_bonus_wallet,
         only: %i[show],
         class: EveryMatrix::FreeSpinBonusWallet,
         eager_load: { wallet: :customer }
  end
end

