namespace :customers do
  namespace :summaries do
    desc 'Reset dashboard report summary'
    task reset: :environment do
      Customers::Summary.delete_all
    end
  end
end
