module Visible
  extend ActiveSupport::Concern

  included do
    scope :visible, -> { where(visible: true) }
    scope :invisible, -> { where(visible: false) }

    def invisible!
      update(visible: false) if visible
    end

    def visible!
      update(visible: true) unless visible
    end
  end
end
