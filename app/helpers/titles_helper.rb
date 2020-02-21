# frozen_string_literal: true

module TitlesHelper
  def translated_attributes_for(attr_name)
    locales_except_en = I18n.available_locales - [:en]

    locales_except_en.map { |l| @title.localized_attr_name_for(attr_name, l) }
  end
end
