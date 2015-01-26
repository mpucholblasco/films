class DelayedJobProgress < ActiveRecord::Base
  before_save :default_values
  def default_values
    self.progress_max ||= 100
    self.progress ||= 0
  end

  self.primary_key='job_id'

  def upgrade_progress(progress)
    self.progress = progress
    self.save()
  end
  
  def finish_process
    self.progress = self.progress_max
    self.save()
  end
end
