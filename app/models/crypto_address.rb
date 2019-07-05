# frozen_string_literal: true

class CryptoAddress < ApplicationRecord
  belongs_to :wallet
end
