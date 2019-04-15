# frozen_string_literal: true

module Findable
  extend ActiveSupport::Concern

  class_methods do
    # rubocop:disable Metrics/LineLength
    # resource_name - name of instance variable where found resource will be placed
    # options includes:
    #   - class          - name of resource class (default: taken from resource_name)
    #   - by             - how value is named in params (default: :id)
    #   - attribute      - name of resource attribute (default: :id)
    #   - strict         - raise error if resource hasn't been found (default: true)
    #   - fallback       - method name/proc which we call if resource hasn't been found
    #   - fallback_value - method name/proc which we call if value can't be found in params
    #   - only           - list of controller actions on which it is triggered
    #   - except         - list of controller actions on which it isn't triggered
    #   - eager_load     - list of eager loaded entries to avoid N+1 problem
    #   - preload        - list of preloaded entries to avoid N+1 problem
    #   - joins          - list of joined entries to avoid N+1 problem
    # rubocop:enable Metrics/LineLength
    #
    def find(resource_name, **options)
      ::Findable::Definition.call(
        controller: self,
        resource_name: resource_name,
        **options
      )
    end
  end
end
