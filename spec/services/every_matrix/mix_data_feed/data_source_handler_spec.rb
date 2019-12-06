# frozen_string_literal: true

describe EveryMatrix::MixDataFeed::DataSourceHandler do
  subject { described_class.call(payload) }

  def context_with_platform(context)
    "#{context}-desktop"
  end

  context 'with valid data source' do
    let(:payload_categories) { payload['data']['categories'] }
    let(:payload_ids) do
      payload['data']['categories'].flat_map do |category|
        category['items'].map { |item| item['id'] }
      end
    end
    let(:payload) { JSON.parse(fixture.read) }

    before do
      payload_ids.each do |id|
        create(:casino_game, external_id: id)
      end
    end

    context 'with all new data' do
      let(:fixture) do
        file_fixture('casino/data_source_multiple_categories_fixture.json')
      end

      it 'creates categories' do
        expect { subject }.to change(EveryMatrix::Category, :count)
          .by(payload_categories.length)
      end

      it 'creates play item categories' do
        expect { subject }.to change(EveryMatrix::PlayItemCategory, :count)
          .by(payload_ids.length)
      end

      it 'creates play items in correct order' do
        subject

        payload_categories.each do |category|
          persisted_ids =
            EveryMatrix::Category
            .find_by(context: context_with_platform(category['id']))
            .play_item_categories
            .order(:position)
            .pluck(:play_item_id)

          expect(persisted_ids)
            .to eq(category['items'].map { |item| item['id'] })
        end
      end
    end

    context 'with changes for category' do
      let(:fixture) do
        file_fixture('casino/data_source_single_category_fixture.json')
      end

      context 'outdated play items' do
        let(:category) do
          create(:category, :with_play_items,
                 context: context_with_platform(payload_categories[0]['id']))
        end

        it 'removes play items' do
          old_ids = category.play_items.pluck(:external_id)

          subject

          new_ids = category.play_items.pluck(:external_id)

          expect(new_ids).not_to include(old_ids)
        end
      end

      context 'position update' do
        let(:payload_ids) do
          payload['data']['categories'].flat_map do |category|
            category['items'].map { |item| item['id'] }
          end
        end
        let(:category) do
          create(
            :category,
            context: context_with_platform(payload_categories[0]['id'])
          )
        end

        before do
          payload_ids.reverse_each do |id|
            create(:play_item_category, play_item_id: id, category: category)
          end
        end

        it 'sets correct position' do
          subject

          new_order = category
                      .play_item_categories
                      .order(:position)
                      .pluck(:position)

          expect(new_order).to eq((0...payload_ids.length).to_a)
        end
      end
    end

    context 'without any changes' do
      let(:fixture) do
        file_fixture('casino/data_source_single_category_fixture.json')
      end

      let(:payload_ids) do
        payload['data']['categories'].flat_map do |category|
          category['items'].map { |item| item['id'] }
        end
      end
      let(:category) do
        create(
          :category,
          context: context_with_platform(payload_categories[0]['id'])
        )
      end
      let(:update_service) do
        EveryMatrix::MixDataFeed::PlayItemCategories::UpdateOrCreateService
      end
      let(:delete_service) do
        EveryMatrix::MixDataFeed::PlayItemCategories::DeleteService
      end

      before do
        payload_ids.each.with_index do |id, index|
          create(:play_item_category,
                 play_item_id: id,
                 category: category,
                 position: index)
        end
      end

      it 'does not trigger update' do
        subject

        expect(update_service).not_to receive(:call)
      end

      it 'does not trigger delete' do
        subject

        expect(delete_service).not_to receive(:call)
      end
    end
  end

  context 'with invalid data source' do
    let(:payload) do
      {
        'data' => {
          'id' => Faker::Lorem.word
        }
      }
    end

    it 'does not process updates' do
      subject

      expect(EveryMatrix::Category).not_to receive(:find_or_create_by)
    end
  end
end
