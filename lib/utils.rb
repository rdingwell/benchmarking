require 'health-data-standards'
module Utils

  def gc_before(&block)
    GC.start
    yield
  end

  def load_configuration(file)
    APP_CONIG.merge(YAML.load(file))
    Mongoid.load!(APP_CONIG["mongoid_yml"],APP_CONIG["mongoid_env"])
  end

  
  def report(name, &block)
      report = Report.new(label: name)
      report.start_time = Time.now
      report.instance_eval &block
      report.save
      report
  end

end