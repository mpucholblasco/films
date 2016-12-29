require 'digest'

class DisksController < ApplicationController
  # We need to include this helper to use it in view
  helper ToolsHelper

  DISK_MOUNT_PATH = '/media/usb/'
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

  def updating_content
    @disk = Disk.find(params[:id])
    logger.info "Updating content for disk #{@disk.inspect}"

    logger.info "Updating disk mounted on <#{DISK_MOUNT_PATH}>"
    begin
      hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(DISK_MOUNT_PATH, @disk.id)
      hard_disk_files_info.process
      respond_to do |format|
        format.json {
          render json: { deleted: hard_disk_files_info.get_files_to_remove.length,
          added: hard_disk_files_info.get_files_to_add.length,
          updated: hard_disk_files_info.get_files_to_update.length }
        }
      end
    rescue Exception => ex
      respond_to do |format|
        format.json {
          render json: { message: ex.message }, status: 500
        }
      end
    end
  end

  private

  def disk_params
    params.require(:disk).permit(:name, :disk_type, :total_size, :free_size)
  end
end
