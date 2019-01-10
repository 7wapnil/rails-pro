shared_context 'frozen_time' do

  before do
    # TODO: Revert to Timecop.freeze when precision fixed
    # https://github.com/travisjeffery/timecop/issues/146
    rounded_random_time =
      Time.at(Random.rand * Time.now.to_i).round
    Timecop.freeze(rounded_random_time)
  end

  after { Timecop.return }
end
