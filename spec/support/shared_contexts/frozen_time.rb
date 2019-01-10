shared_context 'frozen_time' do
  let(:frozen_time) do
    # TODO: Revert to Timecop.freeze when precision fixed
    # https://github.com/travisjeffery/timecop/issues/146
    Time.at(Random.rand * Time.now.to_i).round
  end

  before { Timecop.freeze(frozen_time) }

  after { Timecop.return }
end
