# frozen_string_literal: true

FactoryBot.define do
  factory :address do
    country        { ISO3166::Country.countries.sample.to_s }
    state          { Faker::Address.state }
    city           { Faker::Address.city }
    street_address { Faker::Address.street_address }
    zip_code       { Faker::Address.zip_code }

    customer

    # TODO: refactor when codes would be directly written to db
    trait :with_state do
      country do
        ISO3166::Country.new(
          ::Payments::Fiat::SafeCharge::State::AVAILABLE_STATES.keys.sample
        ).to_s
      end

      state do
        country_details = ISO3166::Country.find_country_by_name(country)
        country_details.subdivision_names_with_codes.to_h.key(
          ::Payments::Fiat::SafeCharge::State::AVAILABLE_STATES
            .fetch(country_details.alpha2)
            .first
        )
      end
    end
  end
end
