class RandomOrCreateStrategy
  def association(runner)
    runner.run
  end

  def result(evaluation)
    model = evaluation.object.class.order(Arel.sql('RANDOM()')).first
    model ||= evaluation.object
    if model.new_record?
      model.save
      evaluation.notify(:after_create, model)
    end
    model
  end
end

FactoryBot.register_strategy(:random_or_create, RandomOrCreateStrategy)
