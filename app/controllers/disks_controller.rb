require "digest"

class DisksController < ApplicationController
  before_action :set_disk, only: %i[ show edit update destroy update_content]
  rescue_from ActiveRecord::RecordNotFound, with: :disk_not_found

  # We need to include this helper to use it in view
  helper ToolsHelper

  def index
    @disks = Disk.order(:name).page params[:page]
  end

  def show
    @file_disks = @disk.file_disks.where(deleted: false).page params[:page]
  end

  def new
    @disk = Disk.new
  end

  def edit
  end

  def update
    logger.debug "Editing disk: #{@disk.attributes.inspect}"

    if @disk.update(disk_params)
      redirect_to @disk
    else
      render "edit"
    end
  end

  def create
    @disk = Disk.new(disk_params)

    if @disk.save
      redirect_to @disk
    else
      respond_to do |format|
        format.turbo_stream {
          @disk.errors.full_messages.each do |e|
            flash.now[:alert] = e
          end

          render turbo_stream: turbo_stream.replace("flash",
            partial: "shared/flash")
        }
      end
    end
  end

  def destroy
    @disk.destroy
    redirect_to disks_path, notice: I18n.t(:disk_deleted_properly)
  end

  def update_content
    job = UpdateDiskInformationJob.perform_later @disk.id
    logger.debug "Updating disk #{@disk.inspect}. Job info: #{job.inspect}"
    redirect_to job_path(job.job_id)
  end

  private

  def set_disk
    @disk = Disk.find(params[:id])
  end

  def disk_params
    params.require(:disk).permit(:name, :disk_type, :total_size, :free_size)
  end

  def disk_not_found
    render :notfound
  end
end
