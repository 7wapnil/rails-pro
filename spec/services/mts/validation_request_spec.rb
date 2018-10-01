describe Mts::Messages::ValidationRequest do
  describe 'example message' do
    let(:example_json) do
      <<-EXAMPLE_JSON
      {"version": "2.0", "timestampUtc": 1486541079460,
      "ticketId": "MTS_Test_20170208_080435399",
      "sender": {"currency": "EUR", "terminalId": "Tallinn-1",
       "channel": "internet", "shopId": null, "bookmakerId": 7669,
       "endCustomer": {"ip": "127.0.0.1", "languageId": "EN",
       "deviceId": "1234test", "id": "1234test", "confidence": 10000 },
       "limitId": 424 }, "selections":
      [{"eventId": 11050343, "id": "lcoo:42/1/*/X", "odds": 28700 }],
      "bets": [{"id": "MTS_Test_20170208_080435391_0",
      "selectionRefs": [{"selectionIndex": 0, "banker": false }],
      "selectedSystems": [1], "stake": {"value": 10000, "type": "total"} }] }
      EXAMPLE_JSON
    end

    let(:bet) { create(:bet) }
    let(:context) { {} }

    let(:message) { described_class.build(context, [bet]) }

    let(:experiment_time) { Time.strptime('1486541079460', '%s') }

    it 'generates correct hash by example' do
      Timecop.freeze(experiment_time) do
        expect(message.to_formatted_hash).to eq(JSON.parse(example_json))
      end
    end
  end
end
