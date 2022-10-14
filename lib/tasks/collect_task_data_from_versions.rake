desc "Collects deleted task data in format date created, time created, service_channel name, media_channel_name. Required options are company_id OR company_name. Optional are file and before_date"

task :collect_deleted_tasks_data => :environment do
  valid = validate_args
  if valid
    company_id = ENV['company_id']
    before_date = ENV['before_date']

    company = Company.find(company_id)
    if company
      service_channel_ids = company.service_channels.pluck(:id)
      task_versions = TaskVersion.where("event = ? AND created_at <= ?","create",before_date)
      puts "Found #{task_versions.length} created tasks"
      data = parse_data(task_versions, service_channel_ids)
    end
  else
    puts "Invalid arguments, not running"
  end
end

def parse_data(task_versions, service_channel_ids)
  parsed_data = []
  media_channel_mappings = map_media_channels
  service_channel_mappings = map_service_channels
  task_versions.each do |tv|
    attrs = PaperTrail.serializer.load(tv.object_changes)
    beautified = {}
    attrs.each do |k,v|
      beautified[k] = v.reject{|i|i.nil? or i.blank?}
    end
    if service_channel_ids.include?(beautified['service_channel_id'][0])
      beautified['service_channel'] = service_channel_mappings[beautified.delete("service_channel_id")[0]]
      beautified['media_channel'] = media_channel_mappings[beautified.delete("media_channel_id")[0]]
      beautified.delete("state")
      beautified.delete("updated_at")
      beautified.delete("id")
      parsed_data << beautified
    end
  end
  puts "Found #{parsed_data.length} created tasks belonging to company"
  generate_csv(parsed_data)
end

def generate_csv(data)
  if ENV['file']
    CSV.open(ENV['file'],"wb") do |csv|
      data.each do |data_row|
        csv << data_row_to_csv_row(data_row)
      end
    end
    puts "CSV generated to #{ENV['file']}"
  else
    csv_string = CSV.generate do |csv|
      data.each do |data_row|
        csv << data_row_to_csv_row(data_row)
      end
    end
    puts csv_string
    puts "If you want the generated data written to file, provide file=path_to_file"
  end
end

def data_row_to_csv_row(data_row)
  [
      data_row['created_at'][0].strftime("%d.%m.%y"),
      data_row['created_at'][0].strftime("%k.%M"),
      data_row['service_channel'],
      data_row['media_channel']
  ]
end

def map_media_channels
  ret = {}
  MediaChannel.all.each do |mc|
    ret[mc.id] = mc.type.split('::')[1]
  end
  ret
end

def map_service_channels
  ret = {}
  ServiceChannel.all.each do |sc|
    ret[sc.id] = sc.name
  end
  ret
end

def validate_args
  company_id = get_company_id
  before_date = ENV['before_date']
  if company_id.nil?
    puts "must provide company_id"
    false
  else
    if !before_date
      ENV['before_date'] = Date.current.to_s
      puts "No date given, assuming now"
    else
      begin
        before_date = Date.parse(before_date)
      rescue
        puts "Invalid date, aborting"
        false
      end
    end
    true
  end
end

def get_company_id
  puts ENV['company_name']
  company = Company.find_by_name(ENV['company_name'])
  if company
    ENV['company_id'] = company.id.to_s
  end
  ENV['company_id']
end
