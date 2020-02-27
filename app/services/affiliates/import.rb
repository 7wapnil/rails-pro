module Affiliates
  class Import < ApplicationService
    require 'csv'

    FIELDS_MAPPING = {
      'Aff. ID' => :b_tag,
      'Username' => :name,
      'Sports %' => :sports_revenue_share,
      'Casino %' => :casino_revenue_share,
      'CPA (€)' => :cost_per_acquisition
    }.freeze

    NUMERIC_ATTRIBUTES = %i[
      sports_revenue_share
      casino_revenue_share
      cost_per_acquisition
    ].freeze

    def initialize(file)
      @file = file
    end

    def call
      CSV.foreach(file, headers: true) do |row|
        attributes = mapped_row(row)
        affiliate =
          Affiliate.find_or_initialize_by(attributes.slice(:name, :b_tag))

        affiliate.assign_attributes(attributes.slice(*NUMERIC_ATTRIBUTES))
        affiliate.save! if affiliate.changed?
      end

      { success: true, message: 'Affiliates imported successfully' }
    rescue StandardError => e
      { success: false, message: e.message }
    end

    private

    attr_reader :file

    def mapped_row(raw_row)
      FIELDS_MAPPING.map do |external_name, internal_name|
        [
          internal_name,
          attribute_value(
            attribute: internal_name,
            value: raw_row[external_name]
          )
        ]
      end.to_h
    end

    def attribute_value(attribute:, value:)
      return value&.to_d if NUMERIC_ATTRIBUTES.include?(attribute)

      value
    end
  end
end
