describe BettingLimitFacade do
  describe '.for_customer' do
    subject(:result) do
      described_class.new(customer_with_limits).for_customer
    end

    let!(:customer_with_limits) do
      create(:customer_with_betting_limits)
    end

    let(:title) { Title.all.first }
    let(:limit_by_title) { BettingLimit.find_by(title: title) }

    it 'returns array with limit by title' do
      expect(
        result
      ).to match_array([{ limit: limit_by_title, title: title }])
    end

    it 'returns correct limit' do
      expect(
        result
          .select { |el| el[:title] && el[:title].id == title.id }
          .first[:limit].user_max_bet
      ).to eq(limit_by_title.user_max_bet)
    end
  end
end
