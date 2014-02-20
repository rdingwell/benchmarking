include Benchmarking

namespace :import do 

  task :bulk_importer, [:working_directory, :number_of_records,:number_of_entries, :force]  => :environment do |t,args|
   rep = report "HDS Bulk Importer: #{args.number_of_records} Records -> #{args.number_of_entries} Entries" do
     working_directory = File.join(args.working_directory,"xml","archive_xml_#{args.number_of_records}")
     archive_name = File.join(args.working_directory,"xml","archive_xml_#{args.number_of_records}.zip")
     generate_archive file_name: archive_name , 
                      number_of_records: args.number_of_records.to_i, 
                      number_of_entries: args.number_of_entries.to_i, 
                      format: :xml, 
                      force: args.force == "true"
     GC.start 
      measure("Importing #{archive_name}") do
        HealthDataStandards::Import::BulkRecordImporter.import_archive(File.new(archive_name),{generate_mrn: false})
      end
    end
    rep.save
    puts ReportGenerator.generate_report(rep)
  end

  desc "importing from zip file" 
  task :import_from_archive,[:working_directory, :number_of_records,:number_of_entries,:format, :no_save, :no_record, :force]  => :environment do |t,args|
     rep = report "Import from archive: #{args.number_of_records} records -> #{args.number_of_entries} entries -> #{args.format} format" do
     working_directory = File.join(args.working_directory,args.format,"archive_#{args.format}_#{args.number_of_records}")
     archive_name = File.join(args.working_directory,args.format,"archive_#{args.format}_#{args.number_of_records}.zip")
     generate_archive file_name: archive_name , number_of_records: args.number_of_records.to_i, number_of_entries: args.number_of_entries.to_i, format: args.format.to_sym, force: args.force == "true"
     drop_collection :records
      GC.start 
      Zip::ZipFile.open(archive_name) do |zip_file|
          entries = zip_file.entries
          length = entries.length
          entries.each do |entry|
            str = nil
            record = nil
            is_json = args.format == "json"
            no_record = args.no_record=="true"
            no_save = args.no_save == "true"
            doc = nil
            measure :read_record_from_zip do
              str = zip_file.read(entry)
            end
            measure :parse_record do
              doc = is_json ? JSON.parse(str, max_nesting: 100) : Nokogiri::XML(str)
            end

            if !is_json
              measure :extracting_providers do 
                begin
                  providers = CDA::ProviderImporter.instance.extract_providers(doc)
                rescue Exception => e
                end
              end
            end
            measure :transform_into_record_object do
              if !is_json 
                doc.root.add_namespace_definition('cda', 'urn:hl7-org:v3')
                doc.root.add_namespace_definition('sdtc', 'urn:hl7-org:sdtc')
              end
              if is_json 
                  record = no_record ? doc : Record.new(doc) 
              else 
                  record = HealthDataStandards::Import::Cat1::PatientImporter.instance.parse_cat1(doc)
              end
            end
            measure :save_to_database do
              if is_json && no_record
                Mongoid.default_session["records"].insert(doc)
              else  
                Record.update_or_create(record,{generate_mrn: true})
              end
            end unless no_save
          end
        end
    end
    rep.save
    puts ReportGenerator.generate_report(rep)
  end


  task :parallel_import_archive,[:working_directory,:number_of_records, :number_of_entries, :format, :number_of_times,:workers,:force,:descrete_measurements, :no_save] => :environment do |t,args|

    #number of archives
    #number of processess
    #make sure that the delayed jobs are stopped
    #clear any old jobs
    #clear record collection
    puts "Attempting to shutdown any old workers"
    stop_delayed_workers
    puts "Clearing old jobs "
    clear_jobs
    puts "droping records collection"
    drop_collection :records
    working_directory=File.join(args.working_directory,args.format,"archive_#{args.format}_#{args.number_of_records}")
    archive = File.join(working_directory, args.format,"archive_#{args.format}_#{args.number_of_records}.zip")
    puts "Generating archive of #{args.number_of_records} "
    generate_archive file_name: archive, 
                     number_of_records: args.number_of_records.to_i, 
                     number_of_entries: args.number_of_entries.to_i, 
                     format: args.format.to_sym, 
                     force: args.force == "true"
    correlation_id = UUID.new.generate
    label = "Import from archive: #{args.number_of_records} records -> #{args.number_of_entries} entries -> #{args.format} format " 
    params = args.to_hash
    params.merge!({label:label, archive: archive, format: args.format.to_sym, correlation_id: correlation_id, descrete_measurement:args.descrete_measurement=="true"})
    puts "Generating #{args.number_of_times} Jobs"
    args.number_of_times.to_i.times do |i|

      ImportJob.new(params).delay.perform

    end
    puts "Starting #{args.workers}"
    start_delayed_workers(args.workers)
    wait_until_finished {
       count = Delayed::Job.count()
       print "\r #{count} Jobs left. "
       STDOUT.flush
     }
    stop_delayed_workers
    bm = Benchmarking::Report.new(params.mereg({label: "Merged: #{label} "}),
                                  correlation_id: correlation_id)
    
    puts "merging results"
    Benchmarking::Report.where(correlation_id: correlation_id).each do |r|
      bm.merge(r)
    end
    bm.save
    puts ReportGenerator.generate_report(bm)
    #start number of workers
    #wait until done
    #create merged results

    end


end

