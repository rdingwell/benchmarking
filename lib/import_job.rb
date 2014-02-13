class ImportJob 

  def initialize(params)
    @params = params
  end

  def perform
    puts "hey"
    @params[:label] ||= "Importing #{@params[:format]} Archive"
    report = Benchmarking::Report.new(@params)
      if @params[:descrete_measurement]
        descrete_measurement(report)
      elsif @params[:format] == :xml
        import_xml_archive(report)
      elsif @params[:format] == :json 
        import_json_archive(report)
      end
    report.save
  end

  def descrete_measurement(report)
    report.measure("Importing #{@params[:archive]}") do
     is_json = @params[:format] == "json"
       Zip::ZipFile.open(@params[:archive]) do |zip_file|
          entries = zip_file.entries
          length = entries.length
          entries.each do |entry|
            str = nil
            record = nil
           
            doc = nil
            report.measure :read_record_from_zip do
              str = zip_file.read(entry)
            end
            report.measure :parse_record do
              doc = is_json ? JSON.parse(str, max_nesting: 100) : Nokogiri::XML(str)
            end

            if !is_json
              report.measure :extracting_providers do 
                begin
                  providers = CDA::ProviderImporter.instance.extract_providers(doc)
                rescue Exception => e
                end
              end
            end
            report.measure :transform_into_record_object do
               if !is_json 
                  doc.root.add_namespace_definition('cda', 'urn:hl7-org:v3')
                  doc.root.add_namespace_definition('sdtc', 'urn:hl7-org:sdtc')
               end
              record = is_json ? Record.new(doc) : HealthDataStandards::Import::Cat1::PatientImporter.instance.parse_cat1(doc)
            end
            report.measure :save_to_database do
             Record.update_or_create(record,{generate_mrn: true})
            end
          end
        end
      end
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