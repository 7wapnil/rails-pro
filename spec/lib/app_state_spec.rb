describe ApplicationState.instance do
  let(:valid_flag) { ApplicationState::ALLOWED_FLAGS.sample }

  context '.initialize' do
    it 'defines defaults status as active' do
      expect(subject.status).to eq(:active)
    end
  end

  context '.status=' do
    it 'sends web socket event on status change' do
      subject.status = :inactive
      expect(WebSocket::Client.instance)
        .to have_received(:emit)
        .with(WebSocket::Signals::APP_STATE_UPDATED, anything)
    end

    it 'raises error on wrong status' do
      expect { subject.status = :unknown }.to raise_error(StandardError)
    end
  end

  context 'flags feature' do
    before(:each) { subject.instance_variable_set(:@flags, []) }

    context '.enable_flag' do
      let(:expected_flags_state) { [valid_flag] }

      before { subject.enable_flag(valid_flag) }

      it 'adds flag to flags array' do
        expect(subject.flags).to match_array(expected_flags_state)
      end

      it 'emits web socket event on flags change' do
        expect(WebSocket::Client.instance)
          .to have_received(:emit)
          .with(
            WebSocket::Signals::APP_STATE_UPDATED,
            flags: expected_flags_state
          )
      end

      context 'guards' do
        it 'does not allow to enable not allowed flag' do
          expect { subject.enable_flag(:invalid) }.to raise_error(ArgumentError)
        end

        context 'idempotent' do
          before { 2.times { subject.enable_flag(valid_flag) } }

          it 'does not produce duplicates' do
            expect(subject.flags).to match_array(expected_flags_state)
          end

          it 'does not emit ws events without change' do
            expect(WebSocket::Client.instance)
              .to have_received(:emit)
              .with(
                WebSocket::Signals::APP_STATE_UPDATED,
                flags: expected_flags_state
              ).once
          end
        end
      end
    end

    context '.disable_flag' do
      let(:expected_flags_state) { [] }

      before do
        subject.instance_variable_set(:@flags, [valid_flag])
        subject.disable_flag(valid_flag)
      end

      it 'disables the flag' do
        expect(subject.flags).to match_array(expected_flags_state)
      end

      it 'emits web socket event on flags change' do
        expect(WebSocket::Client.instance)
          .to have_received(:emit)
          .with(
            WebSocket::Signals::APP_STATE_UPDATED,
            flags: expected_flags_state
          )
      end

      context 'guards' do
        it 'does not allow to disabled not allowed flag' do
          expect { subject.disable_flag(:invalid_flag) }
            .to raise_error(ArgumentError)
        end

        context 'tolerant to repeated calls' do
          before { 2.times { subject.disable_flag(valid_flag) } }

          it 'does not emit ws events without change' do
            expect(WebSocket::Client.instance)
              .to have_received(:emit)
              .with(
                WebSocket::Signals::APP_STATE_UPDATED,
                flags: expected_flags_state
              ).once
          end
        end
      end
    end
  end
end
