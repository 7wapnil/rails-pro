module Visible
  extend ActiveSupport::Concern

  included do
    def invisible!
      update(visible: false) if visible
    end

    def visible!
      update(visible: true) unless visible
    end
  end
end
