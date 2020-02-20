# frozen_string_literal: true

class MonthlyBalanceQueryResultsFilter
  def initialize(page: nil)
    @page = page
  end

  def monthly_balance_query_results
    MonthlyBalanceQueryResultDecorator.decorate_collection(
      MonthlyBalanceQueryResult.order(created_at: :desc).page(@page)
    )
  end
end
