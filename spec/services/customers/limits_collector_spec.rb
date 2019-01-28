# frozen_string_literal: true

describe Customers::LimitsCollector do
  subject { described_class.call(customer: customer) }

  let(:customer) { create(:customer) }

  context 'with single title' do
    let(:limit) { create(:betting_limit, customer: customer) }

    let!(:title) { limit.title }

    let(:entry_for_title) { subject.find { |entry| entry[:title] == title } }
    let(:extracted_limit) { entry_for_title[:limit] }

    before { create(:betting_limit, customer: customer, title: nil) }

    it 'returns array with found limit' do
      expect(subject).to match_array([{ limit: limit, title: title }])
    end

    context 'when limit belongs to another customer' do
      let(:another_customer) { create(:customer) }
      let(:limit) { create(:betting_limit, customer: another_customer) }

      it 'builds new limit' do # rubocop:disable RSpec/MultipleExpectations
        expect(extracted_limit).to be_a BettingLimit
        expect(extracted_limit).to have_attributes(id: nil, title_id: title.id)
      end
    end

    context 'when there is no limit for title' do
      let(:title) { create(:title) }

      it 'builds new limit' do # rubocop:disable RSpec/MultipleExpectations
        expect(extracted_limit).to be_a BettingLimit
        expect(extracted_limit).to have_attributes(id: nil, title_id: title.id)
      end
    end
  end

  context 'when there are found and built limits' do
    let(:found_control_count) { rand(1..3) }
    let(:built_control_count) { rand(3..5) }

    let!(:found_limits) do
      create_list(:betting_limit, found_control_count, customer: customer)
    end

    let!(:titles_without_limits) do
      create_list(:title, built_control_count)
    end

    let(:extracted_found_limits) do
      subject.take(found_control_count).map { |entry| entry[:limit] }
    end

    let(:extracted_titles_for_built_limits) do
      subject.last(built_control_count).map { |entry| entry[:title] }
    end

    it 'found come first' do
      expect(extracted_found_limits).to match_array(found_limits)
    end

    it 'built come last' do
      expect(extracted_titles_for_built_limits)
        .to match_array(titles_without_limits)
    end

    context 'entries are additionally ordered' do
      let(:built_control_count) { 5 }

      let(:ordered_titles) { titles_without_limits.sort_by(&:name) }

      it 'by title name' do
        expect(extracted_titles_for_built_limits).to eq(ordered_titles)
      end
    end
  end
end
