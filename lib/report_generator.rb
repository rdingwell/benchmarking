
class ReportGenerator

  def self.generate_report(reports)
    
    reports = [reports] unless reports.kind_of?(Array)
    str = StringIO.new
    grouped = reports.group_by(&:correlation_id)
    grouped.each_pair do |cid,reports|
      reports.each do |report|
        str.puts  "Report:      #{report.label}"
        str.puts  "Start Time:  #{report.start_time}"
        str.puts  "End Time:    #{report.end_time}"
        str.puts  "Total Time   #{report.end_time - report.start_time}" 
        str.puts  "Ruby Version #{report.ruby_version}"
        str.puts 
        str.puts "Measurements"
         report.aggregate_reports.each do |ag|
            str.puts ""
            str.puts ag.label
            str.puts TablePrint::Printer.new(self.entry_to_hash(ag)).table_print
         end
       end
    end
    str.string
  end


  def self.enerate_excel(reports,file)

  end

  def self.entry_to_hash(ag)
    [ {label: :cstime,  min: ag.cstime.min , max: ag.cstime.max, avg: ag.cstime.avg, total: ag.cstime.total, number_of_measurements: ag.cstime.number_of_entries },
      {label: :cutime,  min: ag.cutime.min , max: ag.cutime.max, avg: ag.cutime.avg, total: ag.cutime.total, number_of_measurements: ag.cutime.number_of_entries },
      {label: :real,    min: ag.real.min , max: ag.real.max, avg: ag.real.avg, total: ag.real.total, number_of_measurements: ag.real.number_of_entries },
      {label: :stime,   min: ag.stime.min , max: ag.stime.max, avg: ag.stime.avg, total: ag.stime.total, number_of_measurements: ag.stime.number_of_entries },
      {label: :utime,   min: ag.utime.min , max: ag.utime.max, avg: ag.utime.avg, total: ag.utime.total, number_of_measurements: ag.utime.number_of_entries },
      {label: :total,   min: ag.total.min , max: ag.total.max, avg: ag.total.avg, total: ag.total.total, number_of_measurements: ag.total.number_of_entries },
    ]
  end



end
