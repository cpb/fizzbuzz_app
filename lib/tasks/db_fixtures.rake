namespace :db do
  namespace :fixtures do
    desc "Export links and gists to YAML fixtures"
    task export: :environment do
      require "fileutils"

      FileUtils.mkdir_p(Rails.root.join("db", "seeds", "fixtures"))

      [ Link, Gist ].each do |model|
        fixture_path = Rails.root.join("db", "seeds", "fixtures", "#{model.table_name}.yml")

        File.open(fixture_path, "w") do |file|
          data = {}
          model.all.each_with_index do |record, index|
            attrs = record.attributes.transform_values do |v|
              v.is_a?(Time) ? v.utc.iso8601(6) : v
            end
            data["record_#{index}"] = attrs
          end
          file.write data.to_yaml
        end

        puts "Exported #{model.count} #{model.table_name} to #{fixture_path}"
      end
    end
  end
end
