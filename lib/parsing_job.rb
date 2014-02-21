class ParsingJob 

  def initialize(params)
    @params = params
    @number_of_entries = @params[:number_of_entries].split("|").collect{|e| e.to_i}
    @number_of_times = @params[:number_of_records].split("|").collect{|e| e.to_i}
    @is_json = @params[:format].to_sym == :json if @params[:format]
  end

def transform
    report = Benchmarking::Report.new(@params)
    @number_of_entries.each do |entries|
      doc = @is_json ? JSON.parse(generate_patient_json(entries),max_nesting:100) : generate_patient_xml(entries,true)
     @number_of_times.each do |i|
        puts "Transform #{entries} entires #{i} times"
        i.times do
          report.measure("Transform #{entries} entires #{i} times") do
           @is_json ? Record.new(doc) : HealthDataStandards::Import::Cat1::PatientImporter.instance.parse_cat1(doc)
          end
        end
      end
    end
    report.save
    report
  end


 def parse
    report = Benchmarking::Report.new(@params)
    @number_of_entries.each do |entries|
      doc = @is_json ? generate_patient_json(entries) : generate_patient_xml(entries)
      @number_of_times.each do |i|
        puts "Parse #{entries} entires #{i} times"
        i.times do
          report.measure("Parse #{entries} entires #{i} times") do
            @is_json ? JSON.parse(doc,max_nesting: 100) : Nokogiri::XML(doc)    
          end
        end
      end
    end
    report.save
    report
  end 

  def saving_to_database
  report = Benchmarking::Report.new(@params)
    @number_of_entries.each do |entries|
      record = generate_patient_json(entries)
      json = JSON.parse(record,max_nesting:100)
      json.delete("_id")
      @number_of_times.each do |i|
        i.times do
          if @params[:no_record]
            report.measure("Save record with  #{entries} entires #{i} times") {
            Mongoid.default_session["records"].insert(json)
          }
          else  
            r= Record.new(json)
            report.measure("Save record with  #{entries} entires #{i} times") {
             r.save
            }
          end
        end
      end
    end
    report.save
    report
  end 
end