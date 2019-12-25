# frozen_string_literal: true

module EveryMatrix
  class GamesByProviderResolver < ApplicationService
    def initialize(provider_name:, device:, country: '')
      @provider_name = provider_name.titleize.delete(' ').downcase
      @device = device
      @country = country
    end

    def call
      return EveryMatrix::PlayItem.none unless subject

      subject
        .play_items
        .public_send(device_platform_scope)
        .reject_country(country)
        .distinct
    end

    private

    attr_reader :provider_name, :device, :country

    def subject
      vendor || content_provider
    end

    def vendor
      @vendor ||= EveryMatrix::Vendor.find_by('LOWER(name) = ?', provider_name)
    end

    def content_provider
      @content_provider ||=
        EveryMatrix::ContentProvider
        .find_by('LOWER(representation_name) = ?', provider_name)
    end

    def device_platform_scope
      return :desktop if device == PlayItem::DESKTOP

      :mobile
    end
  end
end
