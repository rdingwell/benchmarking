class ImportJob 

  def initialize(params)
    @params = params
  end

  def perform
    puts "hey"
    report = Benchmarking::Report.new( label: "Importing #{@params[:format]} Archive", correlation_id: @params[:correlation_id])
      if @params[:format] == :xml
        import_xml_archive(report)
      elsif @params[:format] == :json 
        import_json_archive(report)
      end
    report.save
  end

  def import_json_archive(report)
    
    report.measure("Importing #{@params[:archive]}") do
      Zip::ZipFile.open(@params[:archive]) do |zip_file|
        entries = zip_file.glob("*.json")
        entries.each do |entry|
          json = zip_file.read(entry)
          Record.new(JSON.parse(json,max_nesting: 100)).save!
        end
      end
    end
  end

  def import_xml_archive(report)
    report.measure("Importing #{@params[:archive]}") do
      HealthDataStandards::Import::BulkRecordImporter.import_archive(File.new(@params[:archive]),{generate_mrn: true})
    end
  end


end