include Benchmarking
namespace :archive do

  desc "benchmark archiving records"
  task :generate_archive,[:number_of_records,:number_of_entries,:format,:working_directory] => :environment do |t,args|
   report "archive #{args.format}" do
      GC.start
      archive_name = File.join(args.working_directory,args.format,"archive_#{args.format}_#{args.number_of_records}.zip")
      puts "Archiving #{args.number} records #{archive_name}"
      measure "Archive #{args.number} of files " do 
        generate_archive file_name: archive_name, number_of_records: args.number_of_records.to_i, number_of_entries: args.number_of_entries.to_i, format: args.format.to_sym, force: true
      end
    end.save
  end


  desc "benchmark archiving records"
  task :generate_archive_from_directory,[:number_of_records,:number_of_entries,:format,:working_directory, :native_compression] => :environment do |t,args|
   report "archive #{args.format}" do
      GC.start
      working_directory = File.join(args.working_directory,args.format,"archive_#{args.format}_#{args.number_of_records}")
      archive_name = File.join(args.working_directory,args.format,"archive_#{args.format}_#{args.number_of_records}.zip")
      puts "Generating #{args.number} records #{archive_name}"
      measure "Generating #{args.number} of files " do 
        generate_records working_directory: working_directory, 
                         number_of_records: args.number_of_records.to_i, 
                         number_of_entries: args.number_of_entries.to_i, 
                         format: args.format.to_sym, 
                         force: true

      end
      puts "Archiving #{args.number} records #{archive_name}"
      measure "Archiving #{args.number} of files " do 
       archive_directory working_directory: working_directory, 
                         file_name: archive_name, 
                         force: true,
                         native_compression: args.native_compression == "true"
     end
    end.save
  end

  desc "reading from zip file" 
  task :read_from_archive,[:working_directory, :how_many, :force]  => :environment do |t,args|
     report :read_from_archive do
     working_directory = File.join(args.working_directory,args.format,"archive_#{args.format}_#{args.number_of_records}")
     archive_name = File.join(args.working_directory,args.format,"archive_#{args.format}_#{args.number_of_records}.zip")
     generate_archive file_name: archive_name , number_of_records: args.how_many.to_i, number_of_entries: 100, format: :xml, force: args.force == "true"
      GC.start 
      Zip::ZipFile.open(archive_name) do |zip_file|
          entries = zip_file.glob("*.xml")
          length = entries.length
          entries.each do |entry|
             measure "zip read #{length}" do
              zip_file.read(entry)
            end
          end
        end
    end.save
  end


  desc "reading from directory" 
  task :read_from_directory,[:working_directory, :how_many, :force]  => :environment do |t,args|
    report :read_from_directory do  
      working_directory = File.join(args.working_directory,"xml","archive_#{args.format}_#{args.number_of_records}")
      generate_records working_directory: working_directory , number_of_records: args.how_many.to_i, number_of_entries: 100, format: :xml, force: args.force == "true"
      GC.start
      entries = Dir.glob("#{working_directory}/*.xml")
      length = entries.length
      entries[0..i].each do |entry|
        measure "directory read #{length}" do
        File.read(entry)
      end
     end
    end
  end


  

end