# frozen_string_literal: true

class TitleDecorator < ApplicationDecorator
  def name
    object.name.present? ? object.name : object.external_name
  end

  def short_name
    object.short_name.present? ? object.short_name : name
  end
end
