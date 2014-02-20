
namespace :parsing do


  desc "transformation" 
  task :transformation,[:number_of_entries, :number_of_records, :format]=> :environment do |t,args|
    bm = ParsingJob.new(args.to_hash.merge({label: "#{args.format} transformation"})).transform 
    puts ReportGenerator.generate_report(bm)   
  end

 

  desc "saving to database"
  task :saving_to_database,[:number_of_entries, :number_of_records, :clear_records, :no_record]=> :environment do |t,args|
    drop_collection :records if args.clear_records =="true"
    bm = ParsingJob.new(args.to_hash.merge({label: "#{args.format} saving_to_database"})).saving_to_database 
    puts ReportGenerator.generate_report(bm)   
  end

  desc "parallel saving to database"
  task :parallel_saving_to_database,[:number_of_entries, :number_of_records, :number_of_times,:number_of_workers, :clear_records,  :no_record]=> :environment do |t,args|
    correlation_id = UUID.new.generate
    reset_delayed_jobs_and_workers()
    drop_collection :records if args.clear_records =="true"
    params = args.to_hash.merge({label: "parrallel #{args.format} saving_to_database", correlation_id: correlation_id})
    args.number_of_times.to_i.times do |i|
      ParsingJob.new(params).delay.saving_to_database 
    end
    start_delayed_workers(args.number_of_workers)
    wait_until_finished {
       count = Delayed::Job.count()
       print "\r #{count} Jobs left. "
       STDOUT.flush
     }
    stop_delayed_workers
    params[:label] = "Merged #{params[:label]}"
    bm = Benchmarking::Report.merge_by_correlation_id(correlation_id,params)
    puts ReportGenerator.generate_report(bm)
  end


  desc "parallel transformation" 
  task :parallel_transformation,[:number_of_entries, :number_of_records, :format,:number_of_times, :number_of_workers]=> :environment do |t,args|
    correlation_id = UUID.new.generate
    reset_delayed_jobs_and_workers()
    params = args.to_hash.merge({label: "parrallel #{args.format} transformation", correlation_id: correlation_id})
    args.number_of_times.to_i.times do |i|
      ParsingJob.new(params).delay.transform 
    end
    start_delayed_workers(args.number_of_workers)
    wait_until_finished {
       count = Delayed::Job.count()
       print "\r #{count} Jobs left. "
       STDOUT.flush
     }
    stop_delayed_workers
    params[:label] = "Merged #{params[:label]}"
    bm = Benchmarking::Report.merge_by_correlation_id(correlation_id,params)
    puts ReportGenerator.generate_report(bm)
  end


  desc "parsing"
  task :parse, [:number_of_entries, :number_of_records, :format]=> :environment do |t,args|
    bm = ParsingJob.new(args.to_hash.merge({label: "#{args.format} parsing"})).parse  
    puts ReportGenerator.generate_report(bm)  
  end

end