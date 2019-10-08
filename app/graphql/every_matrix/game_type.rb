# frozen_string_literal: true

module EveryMatrix
  GameType = GraphQL::ObjectType.define do
    name 'Game'

    field :id, !types.ID, property: :external_id
    field :createdAt, types.String, property: :created_at
    field :updatedAt, types.String, property: :updated_at
    field :slug, !types.String
    field :vendor, types.String
    field :contentProvider, types.String, property: :content_provider
    field :categories, !types[types.String]
    field :theoreticalPayout, !types.Float, property: :theoretical_payout
    field :thirdPartyFee, !types.Float, property: :third_party_fee
    field :fpp, !types.Float, property: :fpp
    field :restrictedTerritories, !types[types.String],
          property: :restricted_territories
    field :languages, !types[types.String]
    field :currencies, !types[types.String]
    field :url, types.String
    field :helpUrl, types.String, property: :help_url
    field :externalCreatedAt, types.String, property: :external_created_at
    field :externalUpdatedAt, types.String, property: :external_updated_at
    field :defaultCoin, !types.Int, property: :default_coin
    field :isFreeSpinSupported, !types.Boolean, property: :free_spin_supported
    field :isFreeSpinBonusSupported, !types.Boolean,
          property: :free_spin_bonus_supported
    field :minHitFrequency, !types.Float, property: :min_hit_frequency
    field :maxHitFrequency, !types.Float, property: :max_hit_frequency
    field :isLaunchedInHtml5, !types.Boolean, property: :launch_game_in_html_5
    field :popularityCoefficient, !types.Float,
          property: :popularity_coefficient
    field :popularityRanking, !types.Int, property: :popularity_ranking
    field :hasFunMode, !types.Boolean, property: :play_mode_fun
    field :hasAnonymityMode, !types.Boolean, property: :play_mode_anonymity
    field :hasRealMoneyMode, !types.Boolean, property: :play_mode_real_money
    field :name, !types.String
    field :shortName, types.String, property: :short_name
    field :description, types.String
    field :thumbnailUrl, types.String, property: :thumbnail_url
    field :logoUrl, types.String, property: :logo_url
    field :backgroundImageUrl, types.String, property: :background_image_url
    field :smallIconUrl, types.String, property: :small_icon_url
    field :mediumIconUrl, types.String, property: :medium_icon_url
    field :largeIconUrl, types.String, property: :large_icon_url
    field :topPrize, !types.Float, property: :top_prize
  end
end
