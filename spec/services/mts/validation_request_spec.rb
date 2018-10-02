describe Mts::Messages::ValidationRequest do
  describe 'example message' do
    let(:example_json) do
      <<-EXAMPLE_JSON
      {"version": "2.0", "timestampUtc": 1486541079460,
      "ticketId": "MTS_Test_1486541079460",
      "sender": {"currency": "EUR",
       "channel": "internet", "bookmakerId": 7669,
       "endCustomer": {"ip": "127.0.0.1", "languageId": "EN",
       "id": "12345678" },
       "limitId": 424 }, "selections":
      [{"eventId": 11050343, "id": "lcoo:42/1/*/X", "odds": 28700 }],
      "bets": [{"id": "MTS_Test_1486541079460_0",
      "selectionRefs": [{"selectionIndex": 0, "banker": false }],
      "selectedSystems": [1], "stake": {"value": 10000, "type": "total"} }] }
      EXAMPLE_JSON
    end

    let(:customer) { create(:customer, id: 123_456_78) }

    let(:euro) { create(:currency, code: 'EUR') }
    let(:event) { create(:event, external_id: 'sr:match:11050343') }
    let(:market) { create(:market, event: event) }
    let(:odd) do
      create(:odd, market: market, value: 2.87, external_id: 'lcoo:42/1/*/X')
    end
    let(:bet) do
      create(:bet, amount: 1, odd_value: odd.value,
                   currency: euro, customer: customer, odd: odd)
    end
    let(:context) { {} }

    let(:message) { described_class.new(context, [bet]) }

    let(:experiment_time) { Time.strptime('1486541079460', '%s') }

    it 'generates correct hash by example' do
      Timecop.freeze(experiment_time) do
        expect(message.to_formatted_hash).to eq(JSON.parse(example_json))
      end
    end
  end
end
