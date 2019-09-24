# frozen_string_literal: true

describe OddsFeed::Radar::BetCancelHandler do
  subject { described_class.new(message) }

  let(:message) { XmlParser.parse(file_fixture('bet_cancel_message.xml').read) }

  let!(:event_id) { message.dig('bet_cancel', 'event_id') }
  let!(:event) { create(:event, external_id: event_id) }
  let!(:market) { create(:market, event: event, external_id: "#{event_id}:1") }
  let!(:odds) { create_list(:odd, 3, market: market) }

  let(:entry_kind_cancel) { EntryKinds::SYSTEM_BET_CANCEL }

  include_context 'base_currency'

  it 'cancels accepted bet' do
    bet = create(:bet, :with_placement_entry, :accepted, odd: odds.sample)
    subject.handle
    expect(bet.reload.status).to eq Bet::CANCELLED_BY_SYSTEM
  end

  it 'cancels settled bet' do
    bet = create(:bet, :with_placement_entry, :settled, odd: odds.sample)
    subject.handle
    expect(bet.reload.status).to eq Bet::CANCELLED_BY_SYSTEM
  end

  it 'issues bet refund' do
    Sidekiq::Testing.inline! do
      bet = create(:bet, :with_placement_entry, :accepted, odd: odds.sample)
      subject.handle
      cancellation_entry = Entry.find_by(origin: bet, kind: entry_kind_cancel)
      expect(cancellation_entry).to be_present
    end
  end

  it 'refunds the bet stake' do
    Sidekiq::Testing.inline! do
      bet = create(:bet, :with_placement_entry, :accepted, odd: odds.sample)
      subject.handle
      cancellation_entry = Entry.find_by(origin: bet, kind: entry_kind_cancel)
      expect(cancellation_entry.amount).to eq(-bet.placement_entry.amount)
    end
  end

  it 'refunds the bet stake and subtracts the winning' do
    Sidekiq::Testing.inline! do
      bet = create(:bet, :with_placement_entry, :won, odd: odds.sample)
      subject.handle
      cancellation_entries = Entry.where(origin: bet, kind: entry_kind_cancel)
      stake_rollback = cancellation_entries.where('amount > ?', 0).take
      winning_rollback = cancellation_entries.where('amount < ?', 0).take
      expect(stake_rollback.amount).to eq(-bet.placement_entry.amount)
      expect(winning_rollback.amount).to eq(-bet.winning.amount)
    end
  end

  context 'real money and bonus ratio' do
    let(:stake) { create(:entry, :bet, :with_balance_entries) }
    let(:winning) { create(:entry, :win, :with_balance_entries) }

    let!(:bet) do
      create(:bet, :won, odd: odds.sample,
                         placement_entry: stake,
                         winning: winning)
    end

    it 'refunds correct real money and bonus ratio for stake' do
      subject.handle

      stake_cancellation = Entry
                           .where('amount > ?', 0)
                           .find_by(origin: bet, kind: entry_kind_cancel)

      expect(stake_cancellation.real_money_amount)
        .to eq(-stake.reload.real_money_amount)

      expect(stake_cancellation.bonus_amount)
        .to eq(-stake.bonus_amount)
    end

    it 'subtracts correct real money and bonus ratio for winning' do
      subject.handle

      winning_cancellation = Entry
                             .where('amount < ?', 0)
                             .find_by(origin: bet, kind: entry_kind_cancel)

      expect(winning_cancellation.real_money_amount)
        .to eq(-winning.real_money_amount)

      expect(winning_cancellation.bonus_amount)
        .to eq(-winning.bonus_amount)
    end
  end

  it 'doesn\'t cancel bets that are already cancelled' do
    bet = create(:bet, :with_placement_entry, :cancelled_by_system,
                 odd: odds.sample)
    expect(bet).not_to receive :cancelled_by_system!
    subject.handle
  end

  context 'time ranges' do
    let(:message) do
      XmlParser
        .parse(file_fixture('bet_cancel_message_with_time_ranges.xml').read)
    end

    it 'cancels bets accepted after the start_time' do
      created_at =
        Time.at(message.dig('bet_cancel', 'start_time')[0..-4].to_i) + 5.minutes
      bet = create(:bet, :with_placement_entry, :accepted,
                   odd: odds.sample, created_at: created_at)
      subject.handle
      expect(bet.reload.status).to eq Bet::CANCELLED_BY_SYSTEM
    end

    it 'doesn\'t cancel bets accepted before the start_time' do
      created_at =
        Time.at(message.dig('bet_cancel', 'start_time')[0..-4].to_i) - 5.minutes
      bet = create(:bet, :with_placement_entry, :accepted,
                   odd: odds.sample, created_at: created_at)
      subject.handle
      expect(bet.reload.status).to eq Bet::ACCEPTED
    end

    it 'cancels bets accepted before the end_time' do
      created_at =
        Time.at(message.dig('bet_cancel', 'end_time')[0..-4].to_i) - 5.minutes
      bet = create(:bet, :with_placement_entry, :accepted,
                   odd: odds.sample, created_at: created_at)
      subject.handle
      expect(bet.reload.status).to eq Bet::CANCELLED_BY_SYSTEM
    end

    it 'doesn\'t cancel bets accepted after the end_time' do
      created_at =
        Time.at(message.dig('bet_cancel', 'end_time')[0..-4].to_i) + 5.minutes
      bet = create(:bet, :with_placement_entry, :accepted,
                   odd: odds.sample, created_at: created_at)
      subject.handle
      expect(bet.reload.status).to eq Bet::ACCEPTED
    end
  end
end
