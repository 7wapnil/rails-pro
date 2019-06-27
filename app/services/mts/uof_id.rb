# frozen_string_literal: true

module Mts
  class UofId
    include JobLogger

    VARIANT = 'variant'

    def self.id(odd)
      new(odd).uof_id
    end

    def initialize(odd)
      @odd = odd

      event_producer_failure! unless producer
    end

    # "uof:<product_id>/<sport id>/<market id>/<outcome
    # id>?<specifier1>=<value1>[&<specifierN=valueN>]*"
    def uof_id
      [
        'uof:',
        product_id,
        '/',
        sport_id,
        '/',
        template_id,
        '/',
        outcome_id,
        formatted_specifier
      ].join
    end

    private

    attr_reader :odd

    delegate :producer, :title, to: :event
    delegate :template_id, :template_specifiers, to: :market
    delegate :outcome_id, to: :odd

    def event_producer_failure!
      error = ArgumentError.new('Error with getting producer for event')

      log_job_failure(error)
      raise error
    end

    def product_id
      producer.id
    end

    def event
      @event ||= @odd.market.event
    end

    def market
      @market ||= @odd.market
    end

    def sport_id
      title.external_id
    end

    def formatted_specifier
      "?#{template_specifiers}".tr('|', '&') if template_specifiers.present?
    end
  end
end
