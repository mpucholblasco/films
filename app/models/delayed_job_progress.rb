class DelayedJobProgress < ActiveRecord::Base
  enum finish_status: { UNFINISHED: 1, FINISHED_WITH_ERRORS: 2, FINISHED_CORRECTLY: 3, CANCELLED: 4 }
  before_save :default_values
  def default_values
    self.progress_max ||= 100
    self.progress ||= 0
    self.finish_status ||= :UNFINISHED
  end

  self.primary_key = 'job_id'

  def upgrade_progress(progress, progress_stage = nil)
    self.progress = progress
    self.progress_stage = progress_stage if progress_stage
    self.save
  end

  def cancel
    self.progress = self.progress_max
    self.finish_status = :CANCELLED
    self.progress_stage = I18n.t(:update_content_cancelled)
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

  def is_cancelled?
    self.reload
    self.CANCELLED?
  end

  def self.where_unfinished_or_finished_in_seven_days
    self.where('finish_status = ? OR (finish_status <> ? AND DATE(updated_at) >= ?)', :UNFINISHED, :UNFINISHED, Date.today - 1.week)
  end

  def self.finished_delayed_job
    finished = DelayedJobProgress.new
    finished.progress = 100
    finished.progress_max = 100
    finished.finish_status = :FINISHED_CORRECTLY
    finished.progress_stage = I18n.t(:update_content_finish)
    finished.error_message = nil
    finished.created_at = Time.zone.now,
    finished.updated_at = Time.zone.now,
    finished
  end
end
