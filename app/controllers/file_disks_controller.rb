require 'base64'
require 'uri'

class FileDisksController < ApplicationController
  def show
    @disk = Disk.find(params[:disk_id])
    @file_disk = @disk.file_disks.find(params[:id])
  end

  def create
    @disk = Disk.find(params[:disk_id])
    @file_disk = @disk.file_disks.create(file_disk_params)
    redirect_to disk_path(@disk)
  end

  def destroy
    @disk = Disk.find(params[:disk_id])
    @file_disk = @disk.file_disks.find(params[:id])
    @file_disk.destroy
    redirect_to disk_path(@disk)
  end

  def edit
    @disk = Disk.find(params[:disk_id])
    @file_disk = @disk.file_disks.find(params[:id])
  end

  def update
    @disk = Disk.find(params[:disk_id])
    @file_disk = @disk.file_disks.find(params[:id])
    logger.debug "Editing file disk: #{@file_disk.attributes.inspect}"

    if @file_disk.update(file_disk_params)
      redirect_to (params[:link_to_back].nil? or params[:link_to_back].empty?) ? [@disk, @file_disk] : Base64.decode64(URI.decode(params[:link_to_back]))
    else
      render 'edit'
    end
  end

  private

  def file_disk_params
    params.require(:file_disk).permit(:filename, :size_mb, :score, :disk_id)
  end
end
