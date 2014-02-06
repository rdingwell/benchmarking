require 'benchmark'
require_relative 'models/report.rb'
require_relative 'delayed_job_utils.rb'
require_relative 'mongo_utils.rb'
require_relative 'record_utils.rb'
require_relative 'record_utils.rb'
require_relative 'utils.rb'

module Benchmarking
  include RecordUtils
  include MongoUtils
  include DelayedJobUtils
  include Utils
  # include Configuration
end