module Events
  class MarketQuery < ::Base::Resolver
    type Types::MarketType

    description 'Get one market by ID'

    argument :id, types.ID

    def auth_protected?
      false
    end

    def resolve(_obj, args)
      Market.find_by(id: args[:id])
    end
  end
end
