describe OddsFeed::Radar::Transpiling::Interpreter do
  let(:competitors) do
    create_list(:competitor, 2, :with_players)
  end
  let(:event) do
    create(:event, name: 'Immortals vs Cloud9', competitors: competitors)
  end
  let(:venue_id) { 'sr:venue:1234' }

  before do
    allow(OddsFeed::Radar::Entities::VenueLoader)
      .to receive(:call).with(external_id: venue_id).and_return('Venue')
  end

  describe 'interprets' do
    it 'simple tokens' do
      result = described_class
               .new(event, { set: '1', game: '2', point: '3' }.stringify_keys!)
               .parse('Set is {set}, game is {game}, point is {point}')

      expect(result).to eq('Set is 1, game is 2, point is 3')
    end

    it 'competitor names tokens' do
      result = described_class
               .new(event)
               .parse('{$competitor1} versus {$competitor2}')

      expect(result)
        .to eq("#{competitors[0].name} versus #{competitors[1].name}")
    end

    it 'event name token' do
      result = described_class
               .new(event)
               .parse('Winner of {$event}')

      expect(result).to eq("Winner of #{event.name}")
    end

    it 'ordinal value token' do
      result = described_class
               .new(event, { periodnr: 2 }.stringify_keys!)
               .parse('{!periodnr} period')

      expect(result).to eq('2nd period')
    end

    it 'signed value token' do
      result = described_class
               .new(event, { points: 2 }.stringify_keys!)
               .parse('{+points} points')

      expect(result).to eq('+2 points')
    end

    it 'plus value token' do
      result = described_class
               .new(event, { points: 2 }.stringify_keys!)
               .parse('{points+1} points')

      expect(result).to eq('3 points')
    end

    it 'minus value token' do
      result = described_class
               .new(event, { points: 2 }.stringify_keys!)
               .parse('{points-1} points')

      expect(result).to eq('1 points')
    end

    it 'combined tokens' do
      result = described_class
               .new(event, { winning: 2 }.stringify_keys!)
               .parse('{!(winning+1)} racer winning')

      expect(result).to eq('3rd racer winning')
    end

    it 'player name token' do
      player = competitors.first.players.first
      result = described_class
               .new(event, { player: player.external_id }.stringify_keys!)
               .parse('{%player} was correctly parsed')

      expect(result).to eq("#{player.full_name} was correctly parsed")
    end

    it 'competitor name token' do
      competitor = competitors.first
      result = described_class
               .new(event,
                    { competitor: competitor.external_id }.stringify_keys!)
               .parse('{%competitor} was correctly parsed')

      expect(result).to eq("#{competitor.name} was correctly parsed")
    end

    it 'server name token' do
      competitor = competitors.first
      result = described_class
               .new(event,
                    { server: competitor.external_id }.stringify_keys!)
               .parse('{%server} was correctly parsed')

      expect(result).to eq("#{competitor.name} was correctly parsed")
    end

    it 'venue name token' do
      result = described_class
               .new(event, { venue: venue_id }.stringify_keys!)
               .parse('{%venue} was correctly parsed')

      expect(result).to eq('Venue was correctly parsed')
    end

    context 'unallowed name variable should not been parsed' do
      let(:token)      { '%unallowed_name' }
      let(:raw_string) { "{#{token}} was correctly parsed" }
      let(:message)    { "Name transpiler can't read variable: `#{token}`" }
      let(:interpreter) do
        described_class.new(event)
      end

      it do
        expect(Rails.logger).to receive(:warn).with(message)
        interpreter.parse(raw_string)
      end

      it { expect(interpreter.parse(raw_string)).to eq(raw_string) }
    end
  end
end
