module Mts
  class StubSender
    def self.send_test
      new.send_test_message
    end

    def send_test_message
      Mts::SingleSession.instance.session.within_connection do |conn|
        ch = conn.create_channel
        x = ch.exchange('arcanebet_arcanebet-Submit',
                        type: :fanout,
                        durable: true)
        publish(x, test_body)
      end
    end

    def self.send_test_m
      new.send_multiple_messages
    end

    def send_multiple_messages
      threads = []

      3.times do |i|
        threads << Thread.new do
          sleep 3 - i
          result = send_test_message
          puts "Publish result of #{i} = #{result}"
        end
      end

      threads.map(&:join)
    end

    private

    def publish(exchange, msg)
      exchange.publish(
        msg,
        content_type: 'application/json',
        delivery_mode: 1,
        headers: {
          'replyRoutingKey':
            'rk_for_arcanebet_arcanebet-Confirm_ruby_created_queue'
        }
      )
    end

    def test_body
      <<-EXAMPLE_XML
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
      EXAMPLE_XML
    end
  end
end
