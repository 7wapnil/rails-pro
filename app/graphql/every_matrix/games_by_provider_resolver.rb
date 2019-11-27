# frozen_string_literal: true

module EveryMatrix
  class GamesByProviderResolver < ApplicationService
    def initialize(provider_id:, device:, country: '')
      @provider_id = provider_id
      @device = device
      @country = country
    end

    def call
      provider
        .play_items
        .joins(:categories)
        .where(device_platform_condition)
        .reject_country(country)
        .order(:position)
        .distinct
    end

    private

    attr_reader :provider_id, :device, :country

    def provider
      EveryMatrix::ContentProvider.find(provider_id)
    end

    def device_platform_condition
      {
        every_matrix_categories: {
          platform_type: device
        }
      }
    end
  end
end
