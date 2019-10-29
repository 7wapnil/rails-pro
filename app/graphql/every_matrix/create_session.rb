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
      @play_item = EveryMatrix::PlayItem.find(args['playItemId'])

      return free_game unless args['walletId']

      params = args
               .to_h
               .reject { |param| param == 'playItemId' }
               .deep_transform_keys!(&:underscore)
      params[:subject] = @current_customer
      form = ::Forms::EveryMatrix::CreateSession.new(params)
      form.validate!

      OpenStruct.new(launchUrl: @play_item.url + form.session.id.to_s)
    end

    private

    def free_game
      OpenStruct.new(launchUrl: @play_item.url)
    end
  end
end
