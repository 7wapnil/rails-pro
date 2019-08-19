# frozen_string_literal: true

class TitleDecorator < ApplicationDecorator
  def short_name
    super || name
  end
end
