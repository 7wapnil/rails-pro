describe Heartbeat::Service do
  it 'has products hardcoded' do
    expect(Heartbeat::Service::ALLOWED_PRODUCTS).to eq([1, 3])
  end

  describe '.call' do
    it 'has correct signature' do
      expect(subject)
        .to respond_to(:call)
        .with_keywords(:client, :product, :timestamp, :subscribed)
    end

    context 'subscription active' do
      xit 'saves last successful timestamp for the product'
    end

    context 'subscription lost' do
      describe 'rate limits' do
        context 'rate limits not reached' do
          xit 'sends recovery API call'
          xit 'sends recovery API call with correct timestamp'
          xit 'modifies last successful recovery call'
        end
        context 'rate limits reached' do
          xit 'does not modify last successful recovery call'
          xit 'ignores the request the job'
        end
      end

      # xit 'does not send more than 2 Requests per minute: 1 per 30 seconds'
      # xit 'does not send more than 600 Requests per hour: 1 per 6 seconds'
      xit 'has minimal gap between two recovery calls'
    end

    context 'negative cases' do
      xit 'does not handle invalid client'
      xit 'does not handle invalid product'
      xit 'does not handle invalid timestamp'
      xit 'does not handle invalid subscribed'
    end
  end
end
