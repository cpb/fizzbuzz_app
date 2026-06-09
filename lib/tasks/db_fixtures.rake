namespace :db do
  namespace :fixtures do
    desc "Export links and gists to YAML fixtures"
    task export: :environment do
      require 'fileutils'
      
      FileUtils.mkdir_p(Rails.root.join('db', 'seeds', 'fixtures'))
      
      [Link, Gist].each do |model|
        fixture_path = Rails.root.join('db', 'seeds', 'fixtures', "#{model.table_name}.yml")
        
        File.open(fixture_path, 'w') do |file|
          data = {}
          model.all.each_with_index do |record, index|
            # Use a unique identifier as the key for the fixture
            data["record_#{index}"] = record.attributes
          end
          
          file.write data.to_yaml
        end
      end
      puts "Fixtures exported to db/seeds/fixtures/"
    end
  end
end
