# frozen_string_literal: true

module BetterSluggable
  extend ActiveSupport::Concern

  included do
    extend FriendlyId

    def should_generate_new_friendly_id?
      super || send(friendly_id_config.slug_column).blank?
    end

    def normalize_friendly_id(value)
      value.underscore.parameterize
    end
  end
end
