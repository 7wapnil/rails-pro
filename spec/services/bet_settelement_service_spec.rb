require 'services/service_spec'

describe BetSettelement::Service do
  it_behaves_like 'callable service'

  describe 'initialize' do
    let(:bet) { create(:bet) }

    subject { described_class.new(bet) }

    it 'stores bet value' do
      expect(subject.instance_variable_get(:@bet)).to eq(bet)
    end
  end

  describe 'call' do
    describe 'unexpected bet' do
      context 'pending bet' do
        let(:invalid_bet) { create(:bet, :pending) }

        subject { described_class.new(invalid_bet) }

        it 'ignores unexpected bet state' do
          allow(subject).to receive(:handle_unexpected_bet)
          subject.call
          expect(subject).to have_received(:handle_unexpected_bet)
        end
      end
    end

    context 'bet that can be settled' do
      context 'entire win bet' do
        let(:bet) { create(:bet, :settled, :win) }

        subject { described_class.new(bet) }

        it 'settles bet' do
          allow(subject).to receive(:handle_unexpected_bet)
          allow(subject).to receive(:entry_requests)
          allow(subject).to receive(:apply_requests_to_wallets)

          subject.call
          expect(subject).not_to have_received(:handle_unexpected_bet)
          expect(subject).to have_received(:entry_requests)
          expect(subject).to have_received(:apply_requests_to_wallets)
        end

        let(:win_entry_request) do
          subject.instance_variable_get(:@win_entry_request)
        end

        context 'preparing entry requests' do
          before do
            allow(subject).to receive(:apply_requests_to_wallets)
            subject.call
          end

          it 'creates win entry request of correct type' do
            expect(win_entry_request).to be_an EntryRequest
          end

          it 'creates win entry request with correct params' do
            {
              currency: bet.currency,
              kind: 'win',
              mode: 'sports_ticket',
              initiator: bet.customer,
              customer: bet.customer,
              origin: bet
            }.each do |key, value|
              expect(win_entry_request.send(key)).to eq(value)

              expect(win_entry_request.amount)
                .to be_within(0.01).of(bet.win_amount)
            end
          end
        end

        context 'sending requests for to wallets' do
          before do
            allow(WalletEntry::AuthorizationService).to receive(:call)
            subject.call
          end

          it 'passes win entry request to wallet authorization service' do
            expect(WalletEntry::AuthorizationService)
              .to have_received(:call)
              .with(win_entry_request).exactly(1).times
          end
        end
      end

      context 'half win bet, half refund' do
        let(:bet) { create(:bet, :settled, :win, void_factor: 0.5) }

        subject { described_class.new(bet) }

        it 'settles bet' do
          allow(subject).to receive(:handle_unexpected_bet)
          allow(subject).to receive(:entry_requests)
          allow(subject).to receive(:apply_requests_to_wallets)

          subject.call
          expect(subject).not_to have_received(:handle_unexpected_bet)
          expect(subject).to have_received(:entry_requests)
          expect(subject).to have_received(:apply_requests_to_wallets)
        end

        let(:win_entry_request) do
          subject.instance_variable_get(:@win_entry_request)
        end

        let(:refund_entry_request) do
          subject.instance_variable_get(:@refund_entry_request)
        end

        context 'preparing entry requests' do
          before do
            allow(subject).to receive(:apply_requests_to_wallets)
            subject.call
          end

          it 'creates win entry request of correct type' do
            expect(win_entry_request).to be_an EntryRequest
          end

          it 'creates win entry request with correct params' do
            {
              currency: bet.currency,
              kind: 'win',
              mode: 'sports_ticket',
              initiator: bet.customer,
              customer: bet.customer,
              origin: bet
            }.each do |key, value|
              expect(win_entry_request.send(key)).to eq(value)

              expect(win_entry_request.amount)
                .to be_within(0.01).of(bet.win_amount)
            end
          end

          it 'creates refund entry request of correct type' do
            expect(refund_entry_request).to be_an EntryRequest
          end

          it 'creates refund entry request with correct params' do
            {
              currency: bet.currency,
              kind: 'refund',
              mode: 'sports_ticket',
              initiator: bet.customer,
              customer: bet.customer,
              origin: bet
            }.each do |key, value|
              expect(refund_entry_request.send(key)).to eq(value)

              expect(refund_entry_request.amount)
                .to be_within(0.01).of(bet.refund_amount)
            end
          end
        end

        context 'sending requests for to wallets' do
          before do
            allow(WalletEntry::AuthorizationService).to receive(:call)
            subject.call
          end

          it 'passes win entry request to wallet authorization service' do
            expect(WalletEntry::AuthorizationService)
              .to have_received(:call).exactly(2).times
          end
        end
      end
    end
  end

  describe 'handle_unexpected_bet' do
    xit 'handles unexpected bet'
  end
end
