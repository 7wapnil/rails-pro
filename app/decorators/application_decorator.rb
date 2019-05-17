# frozen_string_literal: true

class ApplicationDecorator < Draper::Decorator
  include Draper::LazyHelpers

  delegate_all

  def self.collection_decorator_class
    PaginationDecorator
  end
end
