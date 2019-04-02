# frozen_string_literal: true

module Findable
  class Finder < ApplicationService
    delegate :params, to: :controller

    def initialize(controller:, resource_name:, **params)
      @controller = controller
      @resource_name = resource_name
      @resource_class = params.fetch(:class) { default_resource_class }
      @by = params.fetch(:by, :id)
      @attribute = params.fetch(:attribute, :id)
      @strict = params.fetch(:strict, true)
      @fallback_parameter = params[:fallback]
      @fallback_value_parameter = params[:fallback_value]
      @options = params
    end

    def call
      resource || fallback(fallback_parameter)
    end

    private

    attr_reader :controller, :resource_name, :resource_class,
                :by, :attribute, :strict, :fallback_parameter,
                :fallback_value_parameter, :options

    def eager_load
      @eager_load ||= options[:eager_load]
    end

    def preload
      @preload ||= options[:preload]
    end

    def joins
      @joins ||= options[:joins]
    end

    def default_resource_class
      resource_name.to_s.camelcase
    end

    def resource
      ::Findable::Find.call(
        resource_class: resource_class,
        value:          value,
        attribute:      attribute,
        strict:         strict?,
        eager_load:     eager_load,
        preload:        preload,
        joins:          joins
      )
    end

    def value
      params.dig(*by) || fallback(fallback_value_parameter)
    end

    def fallback(parameter)
      case parameter
      when Symbol then controller.send(parameter)
      when Proc   then controller.instance_exec(&parameter)
      else             parameter
      end
    end

    def strict?
      fallback_parameter.blank? && strict.present?
    end
  end
end
