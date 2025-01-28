class JobsController < ApplicationController
  before_action :set_job, only: %i[ show update destroy ]
  rescue_from ActiveRecord::RecordNotFound, with: :job_not_found

  def index
    @jobs = Job.where_unfinished_or_finished_in_seven_days.order("created_at DESC").page params[:page]
  end

  def show
  end

  def destroy
    begin
      @job.destroy
      redirect_to jobs_path, notice: I18n.t(:job_deleted_properly)
    rescue JobError => e
      message = case e
      when JobDeletingUnfinishedError
        I18n.t(:job_destroy_error_only_finished)
      else
        I18n.t(:unknown_error)
      end

      respond_to do |format|
        format.turbo_stream {
          flash.now[:alert] = message
          render turbo_stream: turbo_stream.replace("flash",
            partial: "shared/flash")
        }
      end
    end
  end

  def update
    if params[:task] == "cancel"
      logger.info "Cancelling job with ID: #{@job.id}"
      begin
        @job.cancel
        redirect_to jobs_path, notice: I18n.t(:job_canceled_properly)
      rescue JobError => e
        message = case e
        when JobCancellingAlreadyFinishedError
          I18n.t(:job_cancel_error_only_unfished)
        else
          I18n.t(:unknown_error)
        end

        respond_to do |format|
          format.turbo_stream {
            flash.now[:alert] = message
            render turbo_stream: turbo_stream.replace("flash",
              partial: "shared/flash")
          }
        end
      end
    end
  end

  private

  def set_job
    @job = Job.find(params[:id])
  end

  def job_not_found
    render :notfound
  end
end
