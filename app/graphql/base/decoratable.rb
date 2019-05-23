# frozen_string_literal: true

module Base
  module Decoratable
    extend ActiveSupport::Concern

    class_methods do
      attr_reader :decorator_class

      def decorate_with(premade_class = nil)
        @decorator_class = premade_class
      end
    end

    included do
      prepend Decorator::Resolvable
    end
  end
end
