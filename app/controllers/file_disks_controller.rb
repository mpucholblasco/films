require "base64"
require "uri"

class FileDisksController < ApplicationController
  def show
    @disk = Disk.find(params[:disk_id])
    @file_disk = @disk.file_disks.find(params[:id]).page params[:page]
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
      redirect_to (params[:link_to_back].nil? or params[:link_to_back].empty?) ? [ @disk, @file_disk ] : Base64.decode64(CGI.unescape(params[:link_to_back]))
    else
      respond_to do |format|
        format.turbo_stream {
          @file_disk.errors.full_messages.each do |e|
            flash.now[:alert] = e
          end

          render turbo_stream: turbo_stream.replace("flash",
            partial: "shared/flash")
        }
      end
    end
  end

  private

  def file_disk_params
    params.require(:file_disk).permit(:filename, :size_mb, :score, :disk_id)
  end
end
