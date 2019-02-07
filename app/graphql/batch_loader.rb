# frozen_string_literal: true

class BatchLoader < GraphQL::Batch::Loader
  def initialize(model)
    @model = model
  end

  protected

  attr_reader :model
end
