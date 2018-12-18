module LocaleHelper
  def safe_date_localize_helper(date, format: :default, default_result: nil)
    return default_result unless date

    I18n.l(date, format: format)
  end
end
