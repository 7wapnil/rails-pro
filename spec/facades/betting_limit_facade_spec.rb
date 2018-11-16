describe BettingLimitFacade do
  describe '.for_customer' do
    context 'customer without limits' do
      let!(:customer_without_limits) do
        FactoryBot.create(:customer)
      end

      subject(:result) do
        BettingLimitFacade.new(customer_without_limits).for_customer
      end

      it 'returns empty array' do
        expect(result.size).to eq(Title.all.size + 1)
      end
    end

    context 'customer with limit' do
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

      it 'returns array with one title and limit for the view' do
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
end
