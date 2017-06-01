class DelayedJobProgress < ActiveRecord::Base
  enum finish_status: { UNFINISHED: 1, FINISHED_WITH_ERRORS: 2, FINISHED_CORRECTLY: 3 }
  before_save :default_values
  def default_values
    self.progress_max ||= 100
    self.progress ||= 0
    self.finish_status ||= :UNFINISHED
  end

  self.primary_key='job_id'

  def upgrade_progress(progress, progress_stage = nil)
    self.progress = progress
    self.progress_stage = progress_stage if progress_stage
    self.save
  end

  def finish_correctly
    self.progress = self.progress_max
    self.finish_status = :FINISHED_CORRECTLY
    self.save
  end

  def finish_with_errors(error_message)
    self.finish_status = :FINISHED_WITH_ERRORS
    self.error_message = error_message
    self.save
  end
end
