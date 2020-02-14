# frozen_string_literal: true

module Account
  class CountryByRequestQuery < ::Base::Resolver
    type !CountryType

    description 'Get country based on request'

    def auth_protected?
      false
    end

    def resolve(*)
      OpenStruct.new(
        country: country_by_code(@request.location.country_code.upcase)
      )
    end

    private

    def country_by_code(code)
      ISO3166::Country.new(code)&.name
    end
  end
end
