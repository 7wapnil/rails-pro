describe Mts::Messages::ValidationRequest do
  describe 'generates example message' do
    subject { described_class.new([bet]) }

    before do
      allow(ENV).to receive(:[])
        .with('MTS_BOOKMAKER_ID')
        .and_return(bookmaker_id)

      allow(ENV).to receive(:[])
        .with('MTS_MODE')
        .and_return('test')

      allow(ENV).to receive(:fetch)
        .with('MTS_LIMIT_ID')
        .and_return(limit_id)

      Radar::Producer.find_or_create_by!(id: 3)
    end

    let(:bookmaker_id) { Faker::Number.number(5).to_i }
    let(:limit_id) { Faker::Number.number(4).to_i }

    let(:example_json) do
      <<-EXAMPLE_JSON
      {"version": "2.1", "timestampUtc": 1486541079460000, "testSource": true,
      "ticketId": "MTS_Test_1486541079460000",
      "sender": {"currency": "EUR",
       "channel": "internet", "bookmakerId": #{bookmaker_id},
       "endCustomer": {"ip": "202.12.22.4", "languageId": "EN",
       "id": "12345678" },
       "limitId": #{limit_id} }, "oddsChange": "none", "selections":
      [{"eventId":  "sr:match:11050343",
        "id": "uof:3/sr:sport:110/186/4?setnr=1&gamenr=2",
        "odds": 28700 }],
      "bets": [{"id": "MTS_Test_1486541079460000_0",
      "selectionRefs": [{"selectionIndex": 0, "banker": false }],
      "selectedSystems": [1], "stake": {"value": #{base_currency_amount * 10_000}, "type": "total"} }] }
      EXAMPLE_JSON
    end

    let(:customer) do
      create(:customer, id: 123_456_78, current_sign_in_ip: '202.12.22.4')
    end
    let(:base_currency_amount) { Faker::Number.decimal(2, 2).to_d }
    let(:euro) { create(:currency, code: 'EUR') }
    let(:title) { create(:title, external_id: 'sr:sport:110') }
    let(:event) do
      create(:event,
             title: title,
             producer_id: 3,
             external_id: 'sr:match:11050343')
    end
    let(:market) { create(:market, event: event) }
    let(:odd) do
      create(:odd,
             market: market,
             value: 2.87,
             external_id: 'sr:match:11050343:186/setnr=1|gamenr=2:4')
    end
    let(:bet) do
      create(:bet, amount: 1, base_currency_amount: base_currency_amount,
                   odd_value: odd.value,
                   currency: euro,
                   customer: customer,
                   odd: odd)
    end

    let(:experiment_time) { Time.strptime('1486541079460', '%s') }

    it 'generates correct hash by example' do
      Timecop.freeze(experiment_time) do
        expect(subject.to_formatted_hash).to eq(JSON.parse(example_json))
      end
    end
  end
end
