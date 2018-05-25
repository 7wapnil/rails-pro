class Address < ApplicationRecord
  belongs_to :customer

  def to_s
    [street_address, zip_code, state, country].join(', ')
  end
end
