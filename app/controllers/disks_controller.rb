require 'digest'

class DisksController < ApplicationController
  # We need to include this helper to use it in view
  helper ToolsHelper

  def index
    @disks = Disk.paginate(:page => params[:page], per_page: 50).order(:name)
  end

  def show
    @disk = Disk.find(params[:id])
    @file_disks = @disk.file_disks.where(:deleted => false).paginate(:page => params[:page], per_page: 50)
  end

  def new
    @disk = Disk.new
  end

  def edit
    @disk = Disk.find(params[:id])
  end

  def update
    @disk = Disk.find(params[:id])
    logger.debug "Editing disk: #{@disk.attributes.inspect}"

    if @disk.update(disk_params)
      redirect_to @disk
    else
      render 'edit'
    end
  end

  def create
    @disk = Disk.new(disk_params)

    if @disk.save
      redirect_to @disk
    else
      render 'new'
    end
  end

  def destroy
    @disk = Disk.find(params[:id])
    @disk.destroy

    redirect_to disks_path
  end

  def update_content
    @disk = Disk.find(params[:id])
  end

  def update_content_info
    logger.debug("Obtaining update content information for job id #{params[:jobid]}")
    progress = 100
    progress_stage = I18n.t(:update_content_finish)
    finished = true
    begin
      job_progress = DelayedJobProgress.find(params[:jobid])
      progress = job_progress.progress
      progress_stage = job_progress.progress_stage
      finished = job_progress.finished
    rescue ActiveRecord::RecordNotFound
    end
    respond_to do |format|
      format.json {
        render json: { progress: progress, progress_stage: progress_stage, finished: false }, status: 200
      }
    end
  end

  def updating_content
    @disk = Disk.find(params[:id])
    job = UpdateDiskInformationJob.perform_later @disk.id
    logger.debug "Updating disk #{@disk.inspect}. Job info: #{job.inspect}"
    respond_to do |format|
      format.json {
        render json: { job_url: update_content_info_path(@disk, job.job_id) }, status: 200
      }
    end
  end

  private

  def disk_params
    params.require(:disk).permit(:name, :disk_type, :total_size, :free_size)
  end
end
