class BettingLimitFacade
  attr_reader :customer

  def initialize(customer)
    @customer = customer
    @old_elements = []
    @new_elements = []
  end

  def for_customer
    limits = collect_limits_for_customer!
    process_collected_limits!(limits)
    @old_elements + @new_elements
  end

  private

  def collect_limits_for_customer!
    customer_limits = BettingLimit
                      .where(customer: @customer)
                      .to_a
                      .group_by(&:title_id)
    title_list = Title
                 .order(:name)
                 .to_a
                 .each_with_object({}) { |v, h| h[v.id] = [] }
    title_list[nil] = [] # global limit nil title
    title_list.merge customer_limits
  end

  def process_collected_limits!(limits)
    @titles = Title.all
    limits.map do |el|
      limit = el[1].first
      title = @titles.select { |e| e.id == el[0] }.first
      if limit
        @old_elements.push(limit: limit, title: title)
        next
      end

      @new_elements.push(
        limit: BettingLimit.new(customer: @customer, title: title),
        title: title
      )
    end
  end
end
