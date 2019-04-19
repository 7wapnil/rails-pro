# frozen_string_literal: true

class ApplicationState < ApplicationRecord
  def self.instance
    first || create(type: name)
  end
end
