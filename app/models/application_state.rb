# frozen_string_literal: true

class ApplicationState < ApplicationRecord
  def self.instance
    first_or_create
  end
end
