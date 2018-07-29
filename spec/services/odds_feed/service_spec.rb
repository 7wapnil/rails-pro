describe OddsFeed::Service do
  subject { OddsFeed::Service.new({}, {}) }

  it 'should delegate to supported handler' do
    allow_any_instance_of(OddsFeed::Radar::OddsChangeHandler)
      .to receive(:handle).and_return(1)
    expect(subject.call).to eq(1)
  end
end
