# frozen_string_literal: true

describe EveryMatrix::Requests::FindPlayItemService do
  subject { described_class.call(params) }

  context 'with casino game' do
    let(:params) do
      {
        em_game_id: em_game_id,
        game_code: game_code,
        device: device
      }
    end

    let(:expected_game) { create(:casino_game) }
    let(:em_game_id) { expected_game.external_id }
    let(:game_code) { Faker::Lorem.characters(25) }
    let(:device) { EveryMatrix::PlayItem::PLATFORM_TYPES.values.sample }

    it 'finds correct game based on em game id' do
      expect(subject).to eq(expected_game)
    end
  end

  context 'with casino table' do
    let(:params) do
      {
        em_game_id: em_game_id,
        game_code: game_code,
        device: device
      }
    end

    let(:expected_table) { create(:casino_table, :desktop) }
    let(:table_copy_as_game) do
      create(:casino_game,
             game_code: game_code,
             tags: ['LIVEDEALER'])
    end
    let(:em_game_id) { table_copy_as_game.external_id }
    let(:game_code) { expected_table.game_code }
    let(:device) { EveryMatrix::PlayItem::DESKTOP }

    it 'finds correct game based on game code and device' do
      expect(subject).to eq(expected_table)
    end

    context 'with wrong device type' do
      let(:device) { EveryMatrix::PlayItem::MOBILE }
      let(:message) do
        {
          message: 'Primary play item lookup failed. Trying fallback method',
          device: device,
          game_code: game_code,
          em_game_id: em_game_id
        }
      end

      it 'finds correct game based on game code' do
        expect(subject).to eq(expected_table)
      end

      it 'logs info message' do
        expect(Rails.logger).to receive(:info).with(message)

        subject
      end
    end
  end

  context 'unknown game' do
    let(:params) do
      {
        em_game_id: em_game_id,
        game_code: game_code,
        device: device
      }
    end
    let(:device) { EveryMatrix::PlayItem::MOBILE }
    let(:message) do
      {
        message: 'Primary play item lookup failed. Trying fallback method',
        device: device,
        game_code: game_code,
        em_game_id: em_game_id
      }
    end
    let(:game_code) { Faker::Lorem.characters(25) }
    let(:em_game_id) { Faker::Number.number(8) }

    before { allow(Rails.logger).to receive(:info) }

    it 'logs info message' do
      subject

    rescue ActiveRecord::RecordNotFound
      expect(Rails.logger).to have_received(:info).with(message)
    end
  end
end
