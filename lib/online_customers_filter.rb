# frozen_string_literal: true

class OnlineCustomersFilter < CustomersFilter
  MINUTES_DIFFERENCE = 5
  PER_PAGE = 50

  def customers
    search
      .result
      .where(*online_condition)
      .order(id: :desc)
      .page(@page)
      .per(PER_PAGE)
      .includes(:labels, :system_labels)
      .decorate
  end

  private

  def online_condition
    ['last_activity_at > ?', MINUTES_DIFFERENCE.minutes.ago]
  end
end
