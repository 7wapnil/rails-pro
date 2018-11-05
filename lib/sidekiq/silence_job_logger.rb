class SilenceJobLogger
  def call(_item, _queue)
    yield
  end
end
