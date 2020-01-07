# frozen_string_literal: true

module EveryMatrix
  class GamesByProviderResolver < ApplicationService
    def initialize(provider_slug:, device:)
      @provider_slug = provider_slug
      @device = device
    end

    def call
      return EveryMatrix::PlayItem.none unless subject

      subject
        .play_items
        .public_send(device_platform_scope)
        .distinct
    end

    private

    attr_reader :provider_slug, :device

    def subject
      vendor || content_provider
    end

    def vendor
      @vendor ||= EveryMatrix::Vendor.visible.find_by(slug: provider_slug)
    end

    def content_provider
      @content_provider ||=
        EveryMatrix::ContentProvider
        .visible
        .as_vendor
        .find_by(slug: provider_slug)
    end

    def device_platform_scope
      return :desktop if device == PlayItem::DESKTOP

      :mobile
    end
  end
end
