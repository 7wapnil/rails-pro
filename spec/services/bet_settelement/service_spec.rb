describe BetSettelement::Service do
  it_behaves_like 'callable service'

  describe 'initialize' do
    subject(:bet_settlement) { described_class.new(bet) }

    let(:bet) { create(:bet) }

    it 'stores bet value' do
      expect(subject.instance_variable_get(:@bet)).to eq(bet)
    end
  end

  describe 'call' do
    describe 'unexpected bet' do
      context 'pending bet' do
        subject(:bet_settlement) { described_class.new(invalid_bet) }

        let(:invalid_bet) { create(:bet) }

        it 'raises on unexpected bet state' do
          expect(subject).to receive(:handle_unexpected_bet)
          subject.call
        end
      end
    end

    context 'bet that can be settled' do
      context 'entire win bet' do
        subject(:bet_settlement) { described_class.new(bet) }

        let(:bet) { create(:bet, :settled, :won) }

        let(:win_entry_request) do
          bet_settlement.instance_variable_get(:@win_entry_request)
        end

        it 'settles bet' do
          expect(subject).not_to receive(:handle_unexpected_bet)
          expect(subject).to receive(:process_bet_outcome_in_wallets)

          subject.call
        end

        context 'preparing entry requests' do
          let(:win_entry_request_attributes) do
            {
              currency: bet.currency,
              kind: 'win',
              mode: EntryRequest::SYSTEM,
              initiator: bet.customer,
              customer: bet.customer,
              origin: bet
            }
          end

          before do
            allow(WalletEntry::AuthorizationService).to receive(:call)
            subject.call
          end

          it 'creates win entry request of correct type' do
            expect(win_entry_request).to be_an EntryRequest
          end

          it 'creates win entry request with correct params' do
            expect(win_entry_request)
              .to have_attributes(win_entry_request_attributes)

            expect(win_entry_request.amount)
              .to be_within(0.01).of(bet.win_amount)
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
              .with(win_entry_request).once
          end
        end
      end

      context 'half win bet, half refund' do
        subject(:bet_settlement) { described_class.new(bet) }

        let(:bet) { create(:bet, :settled, :won, void_factor: 0.5) }

        let(:refund_entry_request) do
          bet_settlement.instance_variable_get(:@refund_entry_request)
        end
        let(:win_entry_request) do
          bet_settlement.instance_variable_get(:@win_entry_request)
        end

        it 'settles bet' do
          expect(subject).not_to receive(:handle_unexpected_bet)
          expect(subject).to receive(:process_bet_outcome_in_wallets)

          subject.call
        end

        context 'preparing entry requests' do
          let(:refund_entry_request_attributes) do
            {
              currency: bet.currency,
              kind: 'refund',
              mode: EntryRequest::SYSTEM,
              initiator: bet.customer,
              customer: bet.customer,
              origin: bet
            }
          end

          let(:win_entry_request_attributes) do
            {
              currency: bet.currency,
              kind: 'win',
              mode: EntryRequest::SYSTEM,
              initiator: bet.customer,
              customer: bet.customer,
              origin: bet
            }
          end

          before do
            allow(WalletEntry::AuthorizationService).to receive(:call)
            subject.call
          end

          it 'creates win entry request of correct type' do
            expect(win_entry_request).to be_an EntryRequest
          end

          it 'creates win entry request with correct params' do
            expect(win_entry_request)
              .to have_attributes(win_entry_request_attributes)

            expect(win_entry_request.amount)
              .to be_within(0.01).of(bet.win_amount)
          end

          it 'creates refund entry request of correct type' do
            expect(refund_entry_request).to be_an EntryRequest
          end

          it 'creates refund entry request with correct params' do
            expect(refund_entry_request)
              .to have_attributes(refund_entry_request_attributes)

            expect(refund_entry_request.amount)
              .to be_within(0.01).of(bet.refund_amount)
          end
        end

        context 'sending requests for to wallets' do
          before do
            allow(WalletEntry::AuthorizationService).to receive(:call)
            subject.call
          end

          it 'passes win entry request to wallet authorization service' do
            expect(WalletEntry::AuthorizationService)
              .to have_received(:call).twice
          end
        end
      end

      context 'bet lose, half refund' do
        subject(:bet_settlement) { described_class.new(bet) }

        let(:bet) { create(:bet, :settled, :lost, void_factor: 0.5) }

        let(:refund_entry_request) do
          bet_settlement.instance_variable_get(:@refund_entry_request)
        end

        it 'settles bet' do
          expect(subject).not_to receive(:handle_unexpected_bet)
          expect(subject).to receive(:process_bet_outcome_in_wallets)

          subject.call
        end

        context 'preparing entry requests' do
          let(:refund_entry_request_attributes) do
            {
              currency: bet.currency,
              kind: 'refund',
              mode: EntryRequest::SYSTEM,
              initiator: bet.customer,
              customer: bet.customer,
              origin: bet
            }
          end

          before do
            allow(WalletEntry::AuthorizationService).to receive(:call)
            subject.call
          end

          it 'creates refund entry request of correct type' do
            expect(refund_entry_request).to be_an EntryRequest
          end

          it 'creates refund entry request with correct params' do
            expect(refund_entry_request)
              .to have_attributes(refund_entry_request_attributes)

            expect(refund_entry_request.amount)
              .to be_within(0.01).of(bet.refund_amount)
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
              .with(refund_entry_request).once
          end
        end
      end
    end
  end
end
