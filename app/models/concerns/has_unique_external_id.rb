module HasUniqueExternalId
  extend ActiveSupport::Concern

  included do
    validates :external_id, uniqueness: true
  end
end
