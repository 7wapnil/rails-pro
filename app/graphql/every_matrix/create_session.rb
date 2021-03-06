# frozen_string_literal: true

module EveryMatrix
  class CreateSession < ::Base::Resolver
    include DeviceChecker

    argument :walletId, types.Int
    argument :playItemSlug, !types.String

    type EveryMatrix::SessionType

    description 'Generate EveryMatrix session ID for provided wallet'

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      form = ::Forms::EveryMatrix::CreateSession.new(
        wallet_id: args['walletId'],
        play_item_slug: args['playItemSlug'],
        subject: @current_customer,
        country: @request.location.country_code.upcase,
        device: platform_type(@request)
      )

      form.validate!

      OpenStruct.new(launchUrl: form.launch_url, playItem: form.play_item)
    end
  end
end
