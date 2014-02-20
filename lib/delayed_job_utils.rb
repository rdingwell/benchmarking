require 'delayed/command'

Delayed::Worker::DEFAULT_MAX_RUN_TIME = 40.hours
module DelayedJobUtils

def start_delayed_workers(workers=1)
    puts "Starting #{workers}"
    Delayed::Command.new(["start", "-n#{workers}"]).daemonize
  end

  def stop_delayed_workers()
    Delayed::Command.new(["stop"]).daemonize
  end

  def wait_until_finished
     while Delayed::Job.count() > 0 
       sleep 1
       yield if block_given?
     end
  end

  def start_and_wait(workers=1)
      start_delayed_job(workers)
      wait_until_finsihed
  end

  def number_of_current_workers

  end

  def clear_jobs
    Delayed::Job.all.destroy
  end

  def reset_delayed_jobs_and_workers()
    puts "Attempting to shutdown any old workers"
    stop_delayed_workers
    puts "Clearing old jobs "
    clear_jobs

  end
end