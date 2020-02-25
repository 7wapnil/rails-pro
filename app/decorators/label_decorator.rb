# frozen_string_literal: true

class LabelDecorator < ApplicationDecorator
  def decorated_name
    system? ? I18n.t("internal.labels.#{keyword}") : name
  end
end
