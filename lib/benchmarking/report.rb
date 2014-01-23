module Benchmarking
class AggregateItem
    attr_accessor :min, :max , :avg, :total, :number_of_entries
    def initialize()
      @min = nil
      @max = 0
      @avg = 0 
      @total = 0
      @number_of_entries = 0
    end

    def add_report(value)
      @number_of_entries += 1
      @total += value
      @avg = @total.to_f/@number_of_entries.to_f
      @min = (@min.nil? || @min > value )? value : @min
      @max = @max > value ? @max : value
    end

    def to_s
      "min: #{@min} max: #{@max} avg: #{@avg} total #{@total}"
    end
  end

  class AggregateItemReport
    attr_accessor :label, :cstime , :cutime , :real , :utime, :stime, :total
    def initialize(label)
      @label = label
      @cstime = AggregateItem.new
      @cutime = AggregateItem.new
      @real   = AggregateItem.new
      @utime  = AggregateItem.new
      @stime  = AggregateItem.new
      @total  = AggregateItem.new
    end

    def analyze(bm)
      @cstime.add_report(bm.cstime)
      @cutime.add_report(bm.cutime)
      @real.add_report(bm.real)
      @utime.add_report(bm.utime)
      @stime.add_report(bm.stime)
      @total.add_report(bm.total)
    end

    def to_s
      %{ #{@label}
      cstime #{@cstime } 
      cutime #{@cutime} 
      real #{@real }
      utime #{@utime} 
      stime #{@stime } 
      total #{@total} 
      }
    end
  end

  class Report
    attr_accessor :aggregate_reports
    def initialize()
      @aggregate_reports = {}
    end

    def analyze(bm)
      report = (@aggregate_reports[bm.label] ||= AggregateItemReport.new(bm.label))
      report.analyze(bm)
    end

    def to_s
      @aggregate_reports.values.collect{|x| x.to_s}.join("\n")
    end
  end
end
