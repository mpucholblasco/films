class CopyFromServerToExternalJob < ActiveJob::Base
  queue_as :default

  before_enqueue do |job|
    logger.debug "Initializing delayed job progress with job: #{job.inspect}"
    job_progress = DelayedJobProgress.new
    job_progress.job_id = job.job_id
    job_progress.progress_max = 100
    job_progress.save()
  end
  
  after_perform do |job|
    DelayedJobProgress.find(job_id).finish_process
  end

  def perform(*args)
    # Do something later
    logger.debug "Performing CopyFromServerToExternalJob with params #{args.inspect}"
    logger.debug "Job id: #{job_id}"
    job_progress = DelayedJobProgress.find(job_id)
    c = 0
    10.times {
      logger.debug "Sleeping 3 seconds at #{c}"
      job_progress.upgrade_progress(c)
      sleep 3
      c += 10
    }
  end
end
