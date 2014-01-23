require 'health-data-standards'
class Utils

  @@rendering_context = HealthDataStandards::Export::RenderingContext.new
  @@rendering_context.template_helper = HealthDataStandards::Export::TemplateHelper.new('xml', nil,'test/fixtures/cat1_fragments')

  def self.archive_directory(directory, zipfile_name)
    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
        Dir[File.join(directory, '**', '**')].each do |file|
          zipfile.add(file.sub(directory, ''), file)
        end
    end
  end

  def generate_records(how_many,number_of_entries,dir, zip_file=nil)
      record = generate_patient_xml(number_of_entries)
      how_many.times do |i|
        name = File.join(dir,"#{i}_record.xml")
        File.open(name,"w") do |f|
          f.puts record
        end
      end
      if zip_file
        archive_directory(dir,zip_file)
      end
  end


  def self.generate_patient_xml(number_of_entries)  	
    @@rendering_context.render({template: 'wrapper', locals: {number_of_entries: number_of_entries}})
  end

  def self.analyze_benchmarks(bench_marks)
    report = new Benchmarking::Report.new
    bench_marks.each do |bm|
      report.analyze(bm)
    end
  end

end