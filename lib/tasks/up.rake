namespace :up do
  desc 'Import UP customers'
  task import: :environment do
    UP::Import.call(
      ENV['IMPORT_FILE'],
      ENV['ERROR_FILE']
    )
  end
end
