module Benchmarking
class AggregateItem
  include Mongoid::Document
  include Mongoid::Timestamps
    field :lable, type: String
    field :min, type: Float, default: -1
    field :max ,  type: Float, default: 0
    field :avg,  type: Float, default: 0
    field :total,  type: Float, default: 0
    field :number_of_entries, type: Integer, default: 0



    def add_report(value)
      self.number_of_entries += 1
      self.total += value
      self.avg = self.total.to_f/self.number_of_entries.to_f
      self.min = (self.min==-1 || self.min > value )? value : self.min
      self.max = self.max > value ? self.max : value
    end

    def merge(other)
      _min = self.min == -1 ? self.max : self.min
      _other_min = other.min == -1 ? other.max : other.min
      self.min = [_min,_other_min].min 
      self.max = [self.max,other.max].max
      self.total = self.total + other.total
      self.avg = ((self.avg * self.number_of_entries) + (other.avg * other.number_of_entries) ) / (self.number_of_entries + other.number_of_entries)
      self.number_of_entries = self.number_of_entries + other.number_of_entries
      self
    end

    def to_s
      "min: #{min} max: #{max} avg: #{avg} total #{total}"
    end
  end

  class AggregateItemReport
    include Mongoid::Document
    include Mongoid::Timestamps
    field :label,  type: String
    field :start_time, type: Time
    field :end_time, type: Time

    embeds_one :cstime, class_name: "Benchmarking::AggregateItem"
    embeds_one :cutime, class_name: "Benchmarking::AggregateItem"
    embeds_one :real,   class_name: "Benchmarking::AggregateItem"
    embeds_one :utime,  class_name: "Benchmarking::AggregateItem"
    embeds_one :stime,  class_name: "Benchmarking::AggregateItem"
    embeds_one :total,  class_name: "Benchmarking::AggregateItem"

    def initialize(params={})
      super(params)
      self.cstime = AggregateItem.new
      self.cutime = AggregateItem.new
      self.real   = AggregateItem.new
      self.utime  = AggregateItem.new
      self.stime  = AggregateItem.new
      self.total  = AggregateItem.new
    end

    def analyze(bm,start_time,end_time)
      self.start_time = [self.start_time,start_time].compact.min 
      self.end_time =[self.end_time,end_time].compact.max
      self.cstime.add_report(bm.cstime)
      self.cutime.add_report(bm.cutime)
      self.real.add_report(bm.real)
      self.utime.add_report(bm.utime)
      self.stime.add_report(bm.stime)
      self.total.add_report(bm.total)
    end

    def merge(other, clone=false)
      _clone = clone ? self.clone : self
      return _clone if other.nil?
      _clone.cstime.merge(other.cstime)
      _clone.cutime.merge(other.cutime)
      _clone.real.merge(other.real)
      _clone.utime.merge(other.utime)
      _clone.stime.merge(other.stime)
      _clone.total.merge(other.total)
      _clone
    end


    def total_time
      self.end_time - self.start_time
    end

    def to_s
      %{ #{label}
      cstime #{cstime } 
      cutime #{cutime} 
      real #{real }
      utime #{utime} 
      stime #{stime } 
      total #{total} 
      }
    end
  end

  class Report
    include Mongoid::Document
    include Mongoid::Timestamps
    embeds_many :aggregate_reports, class_name: "Benchmarking::AggregateItemReport"
    field :lable, type: String
    field :ruby_version, type: String, default: RUBY_PLATFORM
    field :start_time, type: Time
    field :end_time, type: Time 
    field :correlation_id, type: String

    def analyze(bm, start_time, end_time)
      get_report_by_label(bm.label).analyze(bm,start_time,end_time)
    end

    def get_report_by_label(label)
      report = self.aggregate_reports.where(label:label).first
      unless report
        report = AggregateItemReport.new(label: label) 
        self.aggregate_reports << report
      end
        report
    end

    def get_reports_as_hash
      reports = {}
      self.aggregate_reports.each{|ar| reports[ar.label] = ar}
      reports
    end


    def merge(other,clone=false)
      _clone = clone ? self.clone : self
      _clone.start_time = [self.start_time,other.start_time].compact.min 
      _clone.end_time =[self.end_time,other.end_time].compact.max
      reports = _clone.get_reports_as_hash.merge(other.get_reports_as_hash) do |key, oldval, newval|
        oldval.merge(newval,clone)
      end
      _clone.aggregate_reports = reports.values
      _clone
    end 

     def total_time
        self.end_time - self.start_time
     end

    def total_cpu_time
      self.aggregate_reports.collect{|x| x.total.total }.sum
    end

    def measure(label, &block)
      start_time = Time.now 
      bm = Benchmark.measure(label){ 
        block.call
      }
      end_time = Time.now
      self.analyze(bm,start_time,end_time)
      self.start_time = start_time if self.start_time.nil?
      self.end_time = end_time
    end

    def to_s
      self.aggregate_reports.collect{|x| x.to_s}.join("\n")
    end

    def self.merge_by_correlation_id(correlation_id, params)
    bm = Benchmarking::Report.new(params.merge({correlation_id: correlation_id}))
    Benchmarking::Report.where(correlation_id: correlation_id).each do |r|
      bm.merge(r)
    end
    bm.save
    bm
    end
  end
end
