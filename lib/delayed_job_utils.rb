require 'delayed/command'
module DelayedJobUtils

def start_delayed_workers(workers=1)
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

end