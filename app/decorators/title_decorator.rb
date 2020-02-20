# frozen_string_literal: true

class TitleDecorator < ApplicationDecorator
  def name
    return object.name if object.name.present?

    object.external_name || t('internal.not_available')
  end

  def short_name
    return object.short_name if object.short_name.present?

    name || t('internal.not_available')
  end

  def event_scopes_header
    "#{t('internal.entities.event_scopes')} for #{name}"
  end
end
