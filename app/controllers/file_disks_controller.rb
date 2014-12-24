class FileDisksController < ApplicationController
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

  private

  def file_disk_params
    params.require(:file_disk).permit(:filename, :size_mb)
  end
end
