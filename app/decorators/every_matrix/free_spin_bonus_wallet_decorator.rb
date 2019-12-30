# frozen_string_literal: true

module EveryMatrix
  class FreeSpinBonusWalletDecorator < ApplicationDecorator
    def created_at
      I18n.l(object.created_at)
    end

    def updated_at
      I18n.l(object.updated_at)
    end

    def last_request_body
      pretty_json(object.last_request_body.to_s)
    end

    def last_request_result
      pretty_json(object.last_request_result.to_s)
    end

    private

    def pretty_json(string)
      JSON.pretty_generate(JSON.parse(string))
    end
  end
end

