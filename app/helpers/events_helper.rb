module EventsHelper
  def display_score(event)
    return I18n.t('not_available') unless event.home_score

    "#{event.home_score} : #{event.away_score}"
  end
end