describe Mts::Messages::ValidationResponse do
  let(:rejected_json) do
    <<~EXAMPLE_JSON
      {
         "result":{
            "ticketId":"MTS_Test_1538737411372",
            "status":"rejected",
            "reason":{
               "code":-401,
               "message":"Match is not found in MTS, Selection: uof:3/sr:sport:110/186/4?setnr=1&gamenr=2, Match: "
            },
            "betDetails":[
               {
                  "betId":"MTS_Test_1538737411372_0",
                  "reason":{
                     "code":-401,
                     "message":"Match is not found in MTS, Selection: uof:3/sr:sport:110/186/4?setnr=1&gamenr=2, Match: "
                  },
                  "selectionDetails":[
                     {
                        "selectionIndex":0,
                        "reason":{
                           "code":-401,
                           "message":"Match is not found in MTS, Selection: uof:3/sr:sport:110/186/4?setnr=1&gamenr=2, Match: "
                        },
                        "rejectionInfo":{
                           "eventId":"",
                           "id":"uof:3/sr:sport:110/186/4?setnr=1&gamenr=2",
                           "odds":0
                        }
                     }
                  ]
               }
            ]
         },
         "version":"2.1",
         "signature":"aa4VStP7qEWqm/czafvGQ5PWMv35P6UwfPOoAULRLXs=",
         "exchangeRate":10000
      }
    EXAMPLE_JSON
  end

  describe 'processes rejected response' do
    subject { described_class.new(rejected_json) }

    it 'detects rejection' do
      expect(subject.rejected?).to eq true
    end

    it 'detects reason code' do
      expect(subject.result.reason.code).to eq(-401)
    end

    it 'detects reason message' do
      expect(subject.result.reason.message)
        .to include? 'Match is not found in MTS'
    end

    it 'detects version' do
      expect(subject.message.version).to eq '2.1'
    end
  end

  describe 'initialize' do
    it 'parses input to message variable' do
      input_json = '{"version":"2.1","foo":"bar"}'
      expect_any_instance_of(described_class)
        .to receive(:parse).with(input_json).once.and_call_original
      response = described_class.new(input_json)
      expect(response.instance_variable_get(:@message).foo).to eq 'bar'
    end

    it 'rejects processing unknown version' do
      unsupported_version = 2.0
      expect { described_class.new(%({"version": "#{unsupported_version}"})) }
        .to raise_error(NotImplementedError)
    end
  end
end
