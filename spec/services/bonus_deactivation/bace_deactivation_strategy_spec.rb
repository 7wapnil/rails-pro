describe BonusDeactivation::BaseDeactivationStrategy do
  subject { described_class.new(nil) }
  it 'raise NotImplementedError' do
    expect { subject.call }.to raise_error(NotImplementedError)
  end

  it 'receive #deactivate method' do
    expect(subject).to receive(:deactivate)

    subject.call
  end
end
