require 'ruby-prof'
namespace :profile do  

  desc "xml transformation " 
  task :xml_processing,[:number_of_entries,:number_of_times] => :environment do |t,args| 
    record = generate_patient({number_of_entries: args.number_of_entries.to_i, format: :xml})
    repeat = args.number_of_times.to_i
    doc = Nokogiri::XML(record)
    doc.root.add_namespace_definition('cda', 'urn:hl7-org:v3')
    doc.root.add_namespace_definition('sdtc', 'urn:hl7-org:sdtc')
    RubyProf.start

    repeat.times do |i|
        HealthDataStandards::Import::Cat1::PatientImporter.instance.parse_cat1(doc)
    end
    data = RubyProf.stop
    printer = RubyProf::GraphHtmlPrinter.new(data)
    fprinter = RubyProf::FlatPrinter.new(data)
     fprinter.print(STDOUT) 
    File.open("tmp/xml_parsing_report.html", "w") do |f|
      printer.print(f, :min_percent => 2)   
    end
  end

  task :json_processing,[:number_of_entries,:number_of_times] => :environment do |t,args| 
    record = generate_patient({number_of_entries: args.number_of_entries.to_i, format: :json})
    repeat = args.number_of_times.to_i
    doc = JSON.parse(record,max_nesting:100)
    RubyProf.start
    repeat.times do |i|
        Record.new(doc)
    end
    data = RubyProf.stop
    printer = RubyProf::GraphHtmlPrinter.new(data)
    fprinter = RubyProf::FlatPrinter.new(data)
     fprinter.print(STDOUT) 
    File.open("tmp/json_parsing_report.html", "w") do |f|
      printer.print(f, :min_percent => 2)   
    end
  end

 

end