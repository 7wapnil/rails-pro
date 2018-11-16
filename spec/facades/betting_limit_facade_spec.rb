describe BettingLimitFacade do
  describe '.for_customer' do
    let!(:customer_with_limits) do
      FactoryBot.create(:customer_with_betting_limits)
    end

    subject(:result) do
      BettingLimitFacade.new(customer_with_limits).for_customer
    end

    before do
      @title = Title.all.first
      @global_limit = BettingLimit.find_by(title: nil)
      @limit_by_title = BettingLimit.find_by(title: @title)
    end

    it 'returns array with global limit and limit by title' do
      expect(result).to match_array([
                                      {
                                        limit: @global_limit,
                                        title: nil
                                      },
                                      {
                                        limit: @limit_by_title,
                                        title: @title
                                      }
                                    ])
    end

    it 'returns correct limit' do
      expect(
        result
          .select do |el|
            el[:title] && el[:title].id == @title.id
          end
          .first[:limit]
          .user_max_bet
      ).to eq(@limit_by_title.user_max_bet)
    end
  end
end
