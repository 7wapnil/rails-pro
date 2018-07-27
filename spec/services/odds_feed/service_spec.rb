describe OddsFeed::Service do
  subject { OddsFeed::Service.new({}, {}) }

  it 'should delegate to supported handler' do
    allow_any_instance_of(OddsFeed::Radar::OddsChangeHandler)
      .to receive(:handle)

    subject.call
    expect(OddsFeed::Radar::OddsChangeHandler).to have_received(:handle)
  end
end
