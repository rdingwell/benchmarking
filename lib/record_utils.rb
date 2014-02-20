require 'health-data-standards'
module RecordUtils
  APP_CONIG = YAML.load(File.join(__FILE__,'..','config','benchmark.yml'))
  @@rendering_context = HealthDataStandards::Export::RenderingContext.new
  @@rendering_context.template_helper = HealthDataStandards::Export::TemplateHelper.new('xml', nil,'test/fixtures/cat1_fragments')

  def archive_directory(options)
    return if File.exists?(options[:file_name]) && !options[:force]
    directory = options[:working_directory].sub(%r[/$],'')
    FileUtils.rm options[:file_name], :force=>true

    if options[:native_compression]
      archive_directory_native directory, options[:file_name]
     else 
      file_names = Dir["#{directory}/**/**"].reject{|f|f==options[:file_name]}
      file_names = file_names[0..options[:limit]] if options[:limit]
      add_to_zip(options[:file_name],file_names)
    end
  end

  def archive_directory_native(directory, zipfile)
    puts "native compression"
    exec "zip -rjq #{zipfile} #{directory}"
  end

  def add_to_zip(zipfile_name, file_names)
    Zip::ZipFile.open(zipfile_name, 'w') do |zipfile|
      file_names = file_names.reject{|f|f==zipfile_name}
      file_names.each do |file|
        zipfile.add(file.sub(File.dirname(file)+'/',''),file)
      end
    end
  end

  def generate_archive(options)
    zipfile_name = options[:file_name]
    return if File.exists?(zipfile_name) && !options[:force]
    FileUtils.rm_rf File.dirname(zipfile_name)
    FileUtils.mkdir_p(File.dirname(zipfile_name))
    record = generate_patient(options)   
    Zip::ZipFile.open(zipfile_name, 'w') do |zipfile|
      options[:number_of_records].times do |i|
        zipfile.get_output_stream("#{i}_record.#{options[:format]}"){|io| io.puts record}
      end
    end
  end

  def generate_records(options)
     
     return if File.exists?(options[:working_directory]) && !options[:force]
      record = generate_patient(options)
      FileUtils.rm_rf options[:working_directory]
      FileUtils.mkdir_p(options[:working_directory])
      options[:number_of_records].times do |i|
        name = File.join(options[:working_directory],"#{i}_record.#{options[:format]}")
        File.open(name,"w") do |f|
          f.puts record
        end
      end
      if options[:compress]
        archive_directory(options)
      end
  end

  def generate_patient(options)
    if options[:format].nil? || options[:format] == :xml
      return generate_patient_xml(options[:number_of_entries])
    elsif options[:format] == :json
      return generate_patient_json(options[:number_of_entries])
    else
      raise "Invalid format option"
    end
  end

  def generate_patient_xml(number_of_entries, as_doc=false)  	
    str = @@rendering_context.render({template: 'wrapper', locals: {number_of_entries: number_of_entries}})
    if as_doc
      doc = Nokogiri::XML(str)
     {'cda' => 'urn:hl7-org:v3',
                'sdtc' => 'urn:hl7-org:sdtc',
                'gc32' => 'urn:hl7-org:greencda:c32',
                'ccr' => 'urn:astm-org:CCR',
                'vs' => 'urn:ihe:iti:svs:2008',
                'xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                'hrf-md' => 'http://www.hl7.org/schemas/hdata/2009/11/metadata',
                'nlm' => 'urn:ihe:iti:svs:2008'
                }.each_pair do |k,v|
        doc.root.add_namespace(k,v)
      end
      return doc
    else
      return str
    end
  end


  def generate_patient_json(number_of_entries)   
    record =  @@rendering_context.render({template: 'wrapper', locals: {number_of_entries: number_of_entries}})
    doc = Nokogiri::XML(record)
     {'cda' => 'urn:hl7-org:v3',
                'sdtc' => 'urn:hl7-org:sdtc',
                'gc32' => 'urn:hl7-org:greencda:c32',
                'ccr' => 'urn:astm-org:CCR',
                'vs' => 'urn:ihe:iti:svs:2008',
                'xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                'hrf-md' => 'http://www.hl7.org/schemas/hdata/2009/11/metadata',
                'nlm' => 'urn:ihe:iti:svs:2008'
                }.each_pair do |k,v|
        doc.root.add_namespace(k,v)
     end      
    HealthDataStandards::Import::Cat1::PatientImporter.instance.parse_cat1(doc).as_json(except: [ '_id', 'measure_id' ], methods: ['_type']).to_json
  end


end