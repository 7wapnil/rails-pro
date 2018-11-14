describe BettingLimitFacade do
  let!(:customer) { FactoryBot.create(:customer_with_betting_limit) }

  describe '.for_customer' do
    subject(:example) { BettingLimitFacade.new(customer).for_customer }

    before do
      @title = Title.all.first
      @limit = BettingLimit.find_by(customer: customer)
    end

    it 'returns array of empty betting limits for the view' do
      expect(example).to match_array([{ limit: @limit, title: @title }])
    end
  end
end
