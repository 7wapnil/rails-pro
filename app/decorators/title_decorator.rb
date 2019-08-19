# frozen_string_literal: true

class TitleDecorator < ApplicationDecorator
  def name
    super || external_name
  end

  def short_name
    super || name
  end
end
