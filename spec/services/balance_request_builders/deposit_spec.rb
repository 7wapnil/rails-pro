describe BalanceRequestBuilders::Deposit do
  let(:entry_request) { create(:entry_request) }
  let(:balance_requests) { entry_request.balance_entry_requests }

  it 'returns array of balance entry requests' do
    calculations = { real_money: 100, bonus: 100 }
    build_result = described_class.call(entry_request, calculations)

    expect(build_result).to match_array(balance_requests)
  end

  context 'creates balance entry requests' do
    let(:calculations) { { real_money: 80, bonus: 10 } }

    before do
      described_class.call(entry_request, calculations)
    end

    it 'creates real money and bonus balance entry request' do
      expected_kinds = [Balance::REAL_MONEY, Balance::BONUS]
      balance_requests_kinds = balance_requests.pluck(:kind)

      expect(balance_requests_kinds).to match_array(expected_kinds)
    end

    it 'creates correct real money balance entry request' do
      balance_request = balance_requests.real_money.last

      expect(balance_request.amount).to eq(calculations[:real_money])
    end

    it 'creates correct bonus money balance entry request' do
      balance_request = balance_requests.bonus.last

      expect(balance_request.amount).to eq(calculations[:bonus])
    end
  end

  context 'when calculations has zero values' do
    it "don't create bonus balance entry request when bonus amount is 0" do
      described_class.call(entry_request, bonus: 0, real_money: 10)
      expected_kinds = [Balance::REAL_MONEY]

      expect(balance_requests.pluck(:kind)).to match_array(expected_kinds)
    end

    it "don't create real money balance entry request when real amount is 0" do
      described_class.call(entry_request, bonus: 10, real_money: 0)
      expected_kinds = [Balance::BONUS]

      expect(balance_requests.pluck(:kind)).to match_array(expected_kinds)
    end
  end
end
