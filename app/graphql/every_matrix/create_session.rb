# frozen_string_literal: true

module EveryMatrix
  class CreateSession < ::Base::Resolver
    argument :walletId, types.Int
    argument :playItemId, !types.String

    type EveryMatrix::SessionType

    description 'Generate EveryMatrix session ID for provided wallet'

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      form = ::Forms::EveryMatrix::CreateSession.new(
        wallet_id: args['walletId'],
        play_item_id: args['playItemId'],
        subject: @current_customer
      )

      form.validate!

      OpenStruct.new(launchUrl: form.launch_url)
    end
  end
end
