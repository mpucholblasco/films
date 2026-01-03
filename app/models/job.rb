class JobError < Exception
end

class JobCancellingAlreadyFinishedError < JobError
end

class JobDeletingUnfinishedError < JobError
end

class Job < ApplicationRecord
  enum :finish_status, {
    UNFINISHED: "UNFINISHED", FINISHED_WITH_ERRORS: "FINISHED_WITH_ERRORS",
    FINISHED_CORRECTLY: "FINISHED_CORRECTLY", CANCELLED: "CANCELLED"
  }, prefix: true

  paginates_per 50
  broadcasts_refreshes
  before_destroy :check_finished

  def upgrade_progress(progress, progress_stage = nil)
    self.progress = progress
    self.progress_stage = progress_stage if progress_stage
    self.save
  end

  def cancel
    raise JobCancellingAlreadyFinishedError.new if self.finish_status != "UNFINISHED"
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
    self.finish_status == :CANCELLED
  end

  def self.where_unfinished_or_finished_in_seven_days
    self.where("finish_status = ?", :UNFINISHED).or(
      self.where("finish_status <> ?", :UNFINISHED).and(
        self.where("DATE(updated_at) >= ?", Date.today - 1.week)
      )
    )
  end

  def check_finished
    if self.finish_status == :UNFINISHED
      raise JobDeletingUnfinishedError.new
    end
  end
end
