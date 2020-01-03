# frozen_string_literal: true

describe EveryMatrix::Categories::UpdateService do
  subject { described_class.call(category: category, params: params) }

  let(:category) { create(:category) }

  context 'successful update' do
    let(:params) do
      {
        label: Faker::Lorem.word,
        context: Faker::Lorem.word
      }
    end

    it 'update category attributes' do
      subject
      expect(category).to have_attributes(params)
    end
  end
end
