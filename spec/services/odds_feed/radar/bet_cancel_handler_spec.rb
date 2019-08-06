describe OddsFeed::Radar::BetCancelHandler do
  subject { described_class.new(message) }

  let(:message) do
    XmlParser.parse(file_fixture('bet_cancel_message.xml').read)
  end

  let!(:event_id) { message.dig('bet_cancel', 'event_id') }
  let!(:event) { create(:event, external_id: event_id) }
  let!(:market) { create(:market, event: event, external_id: "#{event_id}:1") }
  let!(:odds) { create_list(:odd, 3, market: market) }

  let(:entry_kind_cancel) { EntryKinds::SYSTEM_BET_CANCEL }

  before do
    create(:currency, :primary)
  end

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

  it 'refunds correct real money and bonus ratio' do
    Sidekiq::Testing.inline! do
      entry = create(:entry, :bet, :with_balance_entries)
      bet = create(:bet, :accepted, odd: odds.sample, placement_entry: entry)
      subject.handle
      cancellation_entry = Entry.find_by(origin: bet, kind: entry_kind_cancel)

      expect(cancellation_entry.real_money_balance_entry.amount)
        .to eq(-entry.real_money_balance_entry.amount)

      expect(cancellation_entry.bonus_balance_entry.amount)
        .to eq(-entry.bonus_balance_entry.amount)
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
        DateTime.strptime(message.dig('bet_cancel', 'start_time'), '%s') +
        5.minutes
      bet = create(:bet, :with_placement_entry, :accepted,
                   odd: odds.sample, created_at: created_at)
      subject.handle
      expect(bet.reload.status).to eq Bet::CANCELLED_BY_SYSTEM
    end

    it 'doesn\'t cancel bets accepted before the start_time' do
      created_at =
        DateTime.strptime(message.dig('bet_cancel', 'start_time'), '%s') -
        5.minutes
      bet = create(:bet, :with_placement_entry, :accepted,
                   odd: odds.sample, created_at: created_at)
      subject.handle
      expect(bet.reload.status).to eq Bet::ACCEPTED
    end

    it 'cancels bets accepted before the end_time' do
      created_at =
        DateTime.strptime(message.dig('bet_cancel', 'end_time'), '%s') -
        5.minutes
      bet = create(:bet, :with_placement_entry, :accepted,
                   odd: odds.sample, created_at: created_at)
      subject.handle
      expect(bet.reload.status).to eq Bet::CANCELLED_BY_SYSTEM
    end

    it 'doesn\'t cancel bets accepted after the end_time' do
      created_at =
        DateTime.strptime(message.dig('bet_cancel', 'end_time'), '%s') +
        5.minutes
      bet = create(:bet, :with_placement_entry, :accepted,
                   odd: odds.sample, created_at: created_at)
      subject.handle
      expect(bet.reload.status).to eq Bet::ACCEPTED
    end
  end
end
