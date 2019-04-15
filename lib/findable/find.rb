# frozen_string_literal: true

module Findable
  class Find < ApplicationService
    def initialize(resource_class:, **params)
      @resource_class = resource_class
      @value          = params[:value]
      @attribute      = params.fetch(:attribute, :id)
      @strict         = params.fetch(:strict, true)
      @eager_load     = params[:eager_load]
      @preload        = params[:preload]
      @joins          = params[:joins]
    end

    def call
      constantized_resource_class
        .eager_load(eager_load)
        .preload(preload)
        .joins(joins)
        .send(finder_method, attribute => value)
    end

    private

    attr_reader :resource_class, :value, :attribute, :strict,
                :eager_load, :preload, :joins

    def constantized_resource_class
      @constantized_resource_class ||= resource_class.to_s.constantize
    rescue NameError
      raise NameError, invalid_resource_class_message
    end

    def invalid_resource_class_message
      "You haven't defined such resource class: `#{resource_class}`."
    end

    def finder_method
      strict ? :find_by! : :find_by
    end
  end
end
