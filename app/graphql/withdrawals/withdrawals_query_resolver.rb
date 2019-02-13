module Withdrawals
  class WithdrawalsQueryResolver
    def initialize(query_args)
      @customer_id = query_args.customerId
      @page = query_args.page
      @per_page = query_args.perPage
    end

    def resolve
      build_query
    end

    private

    attr_reader :customer_id, :per_page, :page

    def build_query
      EntryRequest.withdraw
                  .where(customer_id: customer_id)
                  .page(page)
                  .per(per_page)
    end
  end
end
