module Person
  extend ActiveSupport::Concern

  included do
    def to_s
      full_name
    end

    def full_name
      [first_name, last_name].join(' ')
    end
  end
end
