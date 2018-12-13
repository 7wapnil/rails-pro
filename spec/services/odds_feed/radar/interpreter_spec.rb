describe OddsFeed::Radar::Transpiling::Interpreter do
  let(:event_payload) do
    {
      competitors: {
        competitor: [
          { id: '1000', name: 'Player 1' },
          { id: '1001', name: 'Player 2' }
        ]
      }
    }.stringify_keys!
  end
  let(:event_name) { 'Immortals vs Cloud9' }
  let(:event) do
    create(:event,
           name: 'Immortals vs Cloud9',
           payload: event_payload)
  end

  describe 'transpiling' do
    [
      {
        description: 'simple tokens',
        value: 'Set is {set}, game is {game}, point is {point}',
        specifiers: { set: '1', game: '2', point: '3' },
        result: 'Set is 1, game is 2, point is 3'
      },
      {
        description: 'competitor names tokens',
        value: '{$competitor1} versus {$competitor2}',
        specifiers: {},
        result: 'Player 1 versus Player 2'
      },
      {
        description: 'event name token',
        value: 'Winner of {$event}',
        specifiers: {},
        result: 'Winner of Immortals vs Cloud9'
      },
      {
        description: 'ordinal value token',
        value: '{!periodnr} period',
        specifiers: { periodnr: 2 },
        result: '2nd period'
      },
      {
        description: 'signed value token',
        value: '{+points} points',
        specifiers: { points: 2 },
        result: '+2 points'
      },
      {
        description: 'plus value token',
        value: '{points+1} points',
        specifiers: { points: 2 },
        result: '3 points'
      },
      {
        description: 'minus value token',
        value: '{points-1} points',
        specifiers: { points: 2 },
        result: '1 points'
      },
      {
        description: 'combined tokens',
        value: '{!(winning+1)} racer winning',
        specifiers: { winning: 2 },
        result: '3rd racer winning'
      }
    ].each do |test_data|
      it "interprets '#{test_data[:description]}'" do
        interpreter = OddsFeed::Radar::Transpiling::Interpreter
                      .new(event, test_data[:specifiers].stringify_keys)

        expect(interpreter.parse(test_data[:value])).to eq(test_data[:result])
      end
    end

    describe 'name expression transpiler' do
      player_id     = 'sr:player:1234'
      competitor_id = 'sr:competitor:1234'
      venue_id      = 'sr:venue:1234'

      before do
        allow(OddsFeed::Radar::Entities::PlayerLoader)
          .to receive(:call).with(external_id: player_id).and_return('Player')

        allow(OddsFeed::Radar::Entities::CompetitorLoader)
          .to receive(:call)
          .with(external_id: competitor_id)
          .and_return('Competitor')

        allow(OddsFeed::Radar::Entities::VenueLoader)
          .to receive(:call).with(external_id: venue_id).and_return('Venue')
      end

      [
        {
          description: 'Name token - Player',
          value:  '{%player} was correctly parsed',
          specifiers: { player: player_id },
          result: 'Player was correctly parsed'
        },
        {
          description: 'Name token - Competitor',
          value:  '{%competitor} was correctly parsed',
          specifiers: { competitor: competitor_id },
          result: 'Competitor was correctly parsed'
        },
        {
          description: 'Name token - Venue',
          value:  '{%venue} was correctly parsed',
          specifiers: { venue: venue_id },
          result: 'Venue was correctly parsed'
        }
      ].each do |test_data|
        it "interprets '#{test_data[:description]}'" do
          interpreter = OddsFeed::Radar::Transpiling::Interpreter
                        .new(event, test_data[:specifiers].stringify_keys)

          expect(interpreter.parse(test_data[:value])).to eq(test_data[:result])
        end
      end

      context 'unallowed name variable should not been parsed' do
        let(:token)      { '%unallowed_name' }
        let(:raw_string) { "{#{token}} was correctly parsed" }
        let(:message)    { "Name transpiler can't read variable: `#{token}`" }
        let(:interpreter) do
          OddsFeed::Radar::Transpiling::Interpreter.new(event)
        end

        it do
          expect(Rails.logger).to receive(:warn).with(message)
          interpreter.parse(raw_string)
        end

        it { expect(interpreter.parse(raw_string)).to eq(raw_string) }
      end
    end
  end
end
