# frozen_string_literal: true

describe EveryMatrix::MixDataFeed::GameHandler do
  subject { described_class.call(payload) }

  context 'with valid payload' do
    let(:params) do
      {
        id: play_item_id,
        vendorID: vendor.vendor_id,
        contentProvider: content_provider.representation_name,
        creation: {
          time: Time.zone.now,
          newGameExpiryTime: 2.days.from_now
        },
        popularity: {
          coefficient: 1.0,
          ranking: 10
        },
        presentation: {
          gameName: {
            '*' => game_name
          }
        },
        playMode: {
          fun: true
        },
        bonus: {
          contribution: 1.0
        },
        property: {
          freeSpin: { support: true },
          hitFrequency: {
            min: Faker::Number.decimal(2),
            max: Faker::Number.decimal(2)
          }
        }
      }
    end
    let(:vendor) { create(:every_matrix_vendor) }
    let(:content_provider) { create(:every_matrix_content_provider) }

    context 'new play item' do
      let(:payload) { { action: action, data: params }.deep_stringify_keys }
      let(:action) { 'update' }
      let(:play_item_id) { Faker::Number.number(5) }
      let(:game_name) { Faker::Lorem.word }
      let(:free_spin) { params.dig(:property, :freeSpin, :support) }
      let(:min_hit_frequency) { params.dig(:property, :hitFrequency, :min) }
      let(:max_hit_frequency) { params.dig(:property, :hitFrequency, :max) }

      it 'creates play item' do
        expect { subject }.to change(EveryMatrix::PlayItem, :count).by(1)
      end

      it 'assigns game details' do
        subject

        play_item = EveryMatrix::PlayItem.find(params[:id].to_s)

        expect(play_item.details)
          .to have_attributes(
            game: play_item,
            free_spin_supported: free_spin,
            min_hit_frequency: min_hit_frequency.to_d,
            max_hit_frequency: max_hit_frequency.to_d
          )
      end
    end

    context 'update play item' do
      let(:payload) { { action: action, data: params }.deep_stringify_keys }
      let(:action) { 'update' }
      let(:play_item) { create(:casino_game) }
      let(:play_item_id) { play_item.id }
      let(:game_name) { Faker::Lorem.word }

      it 'updates existing play item' do
        subject

        expect(play_item.reload.name).to eq(game_name)
      end
    end

    context 'remove play item' do
      let(:payload) do
        {
          action: action,
          data: nil,
          id: play_item.external_id
        }.deep_stringify_keys
      end
      let(:action) { 'update' }
      let(:play_item) { create(:casino_game) }

      it 'deactivate play item' do
        subject

        expect(play_item.reload.external_status)
          .to eq(EveryMatrix::PlayItem::DEACTIVATED)
      end

      it 'writes logs' do
        expect(Rails.logger)
          .to receive(:info).with(message: 'Play Item deactivated on EM side',
                                  external_id: play_item.external_id)

        subject
      end
    end
  end
end
