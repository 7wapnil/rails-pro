module Mts
  module Messages
    class ValidationRequest
      def self.build(_, _)
        return new
      end

      def to_json
        return <<-EXAMPLE_JSON
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
    end
  end
end

