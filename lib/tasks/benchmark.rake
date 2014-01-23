namespace :benchmark do

	namespace :xml do
		desc "benchmark xml parsing"
		task :xml_parsing do 
      report = Benchmarking::Report.new
      record_0 = Utils.generate_patient_xml(0)
      record_10 = Utils.generate_patient_xml(10)
      record_100 = Utils.generate_patient_xml(100)
      record_1000 = Utils.generate_patient_xml(1000)
      [1,10,100,1000].each do |i|
        i.times do 
          report.analyze(Benchmark.measure("Parse 0 entires #{i} times") {Nokogiri::XML(record_0)})
          report.analyze(Benchmark.measure("Parse 10 entires #{i} times ") {Nokogiri::XML(record_10)})
          report.analyze(Benchmark.measure("Parse 100 entires #{i} times") {Nokogiri::XML(record_100)})
          report.analyze(Benchmark.measure("Parse 1000 entires #{i} times") {Nokogiri::XML(record_1000)})
        end
      end
      puts report.to_s
		end
	end
  
  namespace :json do
  	desc "benchmark json parsing"
  	task :json_parsing do

  	end
  end

  namespace :archive do

    desc "reading from zip file" 
    task :read do

    end

    desc "import archives" 
    task :import do

    end
  end

end