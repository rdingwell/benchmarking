
namespace :parsing do
  desc "benchmark xml parsing"
  task :xml, [:number_of_entries, :number_of_times] => :environment do |t,args|
    puts args
    report = Benchmarking::Report.new(label: "Parsing xml")
    number_of_entries = args.number_of_entries.split("|").collect{|e| e.to_i}
    number_of_times = args.number_of_times.split("|").collect{|e| e.to_i}
    number_of_entries.each do |entries|
      record = generate_patient_xml(entries)
      number_of_times.each do |i|
        puts "Parse #{entries} entires #{i} times "
        i.times do 
          report.measure("Parse #{entries} entires #{i} times") {Nokogiri::XML(record)}
        end
        end
      end
    report.save
  end

  desc "benchmark xml parsing"
  task :json,[:number_of_entries, :number_of_times] => :environment do |t,args|
    report = Benchmarking::Report.new(label: "Parsing json")
    number_of_entries = args.number_of_entries.split("|").collect{|e| e.to_i}
    number_of_times = args.number_of_times.split("|").collect{|e| e.to_i}
    number_of_entries.each do |entries|
      record = generate_patient_json(entries)
      number_of_times.each do |i|
        puts "Parse #{entries} entires #{i} times "
        i.times do
          report.measure("Parse #{args.number_of_entries} entires #{args.number_of_times} times") {JSON.parse(record, max_nesting: 100)}
        end
      end
    end
    report.save
  end
end