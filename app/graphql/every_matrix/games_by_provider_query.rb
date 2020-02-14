# frozen_string_literal: true

module EveryMatrix
  class GamesByProviderQuery < ::Base::Resolver
    include ::Base::Pagination
    include DeviceChecker

    type !types[PlayItemType] do
      field :provider, EveryMatrix::ProviderType
    end

    description 'List of games by provider'

    argument :providerSlug, !types.String

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      find_subject!(args)

      return EveryMatrix::PlayItem.none unless @subject

      @subject
        .play_items
        .public_send(device_platform_scope)
        .reject_country(country)
        .distinct
    end

    private

    def extend_pagination_result(*)
      { provider: @subject }
    end

    def find_subject!(args)
      @subject = EveryMatrix::Providers::FindForApi.call(
        slug: args['providerSlug']
      )
    end

    def device_platform_scope
      return :desktop if platform_type(@request) == PlayItem::DESKTOP

      :mobile
    end

    def country
      @request.location.country_code.upcase
    end
  end
end
