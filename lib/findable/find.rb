# frozen_string_literal: true

module Findable
  class Find < ApplicationService
    include Strategies::FriendlyId

    def initialize(resource_class:, **params)
      @resource_class = resource_class
      @value          = params[:value]
      @attribute      = params.fetch(:attribute, :id)
      @strict         = params.fetch(:strict, true)
      @eager_load     = params[:eager_load]
      @preload        = params[:preload]
      @joins          = params[:joins]
      @friendly       = params[:friendly]
    end

    def call
      constantize_resource_class!
      verify_strategies!
      find_resource!
    end

    private

    attr_reader :resource_class, :value, :attribute, :strict,
                :eager_load, :preload, :joins, :friendly,
                :constantized_resource_class

    def constantize_resource_class!
      @constantized_resource_class = resource_class.to_s.constantize
    rescue NameError
      raise NameError, invalid_resource_class_message
    end

    def invalid_resource_class_message
      "You haven't defined such resource class: `#{resource_class}`."
    end

    def verify_strategies!
      verify_friendly_id_strategy!
    end

    def find_resource!
      constantized_resource_class
        .eager_load(eager_load)
        .preload(preload)
        .joins(joins)
        .yield_self(&method(:apply_search_strategy!))
    end

    def apply_search_strategy!(scope)
      return apply_friendly_id_strategy!(scope) if friendly

      constantized_resource_class.send(finder_method, attribute => value)
    end

    def finder_method
      strict ? :find_by! : :find_by
    end
  end
end
