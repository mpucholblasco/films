class JobsController < ApplicationController
  def index
    @jobs = DelayedJobProgress.where_unfinished_or_finished_in_seven_days.paginate(:page => params[:page], per_page: 50).order('created_at DESC')
  end

  def show
    begin
      @job = DelayedJobProgress.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      @job = DelayedJobProgress.finished_delayed_job
    end
    respond_to do |format|
      format.html
      format.json {
        render json: {
          progress: @job.progress,
          progress_stage: @job.progress_stage,
          finish_status: @job.finish_status,
          error_message: @job.error_message,
          created_at: @job.created_at,
          updated_at: @job.updated_at,
        }, status: 200
      }
    end
  end

  def destroy
    job = DelayedJobProgress.find(params[:id])
    job.destroy
    redirect_to jobs_path
  end

  def update
    job = DelayedJobProgress.find(params[:id])
    if params[:task] == 'cancel'
      logger.info "Cancelling job with ID: #{job.job_id}"
      job.cancel
    end
    redirect_to jobs_path
  end
end
