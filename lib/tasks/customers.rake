namespace :customers do
  namespace :statistics do
    desc 'Reset account overview for all customers'
    task reset: :environment do
      Customers::Statistic.delete_all
    end
  end

  namespace :summaries do
    desc 'Reset dashboard report summary'
    task reset: :environment do
      Customers::Summary.delete_all
    end
  end
end
