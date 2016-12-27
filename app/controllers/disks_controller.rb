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
    @file_disks = @disk.file_disks.paginate(:page => params[:page], per_page: 50)
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
      disk = TasksHelper::HardDiskInfo.read_from_mounted_disk(DISK_MOUNT_PATH)
      disk.ensure_exists
      if disk.id != @disk.id
        respond_to do |format|
          format.json {
            render json: { message: t(:update_error_inserted_disk_is_not_updating_one, :inserted_disk => disk.name, :updating_disk => @disk.name) }, status: 500
          }
        end
      else
        logger.info "Found disk info: #{disk.inspect}"
        hard_disk_files_info = TasksHelper::HardDiskFilesInfo.new(DISK_MOUNT_PATH, @disk.id, True)
        TasksHelper::HardDiskInfo.transaction do
          logger.info "Going to delete <#{hard_disk_files_info.get_files_to_remove.length}>"
          hard_disk_files_info.get_files_to_remove.each do |file|
            file.delete
          end
          logger.info "Going to add <#{hard_disk_files_info.get_files_to_add.length}>"
          hard_disk_files_info.get_files_to_add.each do |file|
            begin
              file.hash_id = Digest::SHA256.file(file.filename).hexdigest
              hash_file = HashFile.new
              hash_file.id = file.hash_id
              hash_file.save # ignored if hash already exists
              file.save
            rescue ActiveRecord::RecordNotUnique
              logger.error "Duplicated file <#{file.filename}"
              respond_to do |format|
                format.json {
                  render json: { message: t(:update_error_duplicated_file, :duplicated_filename => file.filename) }, status: 500
                }
              end
            end
          end
          @disk.last_sync = Time.zone.now
          @disk.total_size = disk.total_size
          @disk.free_size = disk.free_size
          @disk.save()
        end
        respond_to do |format|
          format.json {
            render json: { deleted: hard_disk_files_info.get_files_to_remove.length,
            added: hard_disk_files_info.get_files_to_add.length }
          }
        end
      end
    rescue ActiveRecord::RecordNotFound
      logger.error "Found disk info, but disk does not exist on DB"
      respond_to do |format|
        format.json {
          render json: { message: t(:update_error_disk_not_in_db) }, status: 500
        }
      end
    rescue IOError
      logger.error "Disk information not found"
      respond_to do |format|
        format.json {
          render json: { message: t(:update_error_disk_information_not_found) }, status: 500
        }
      end
    end
  end

  private

  def disk_params
    params.require(:disk).permit(:name, :disk_type, :total_size, :free_size)
  end
end
