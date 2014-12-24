class DisksController < ApplicationController
  def index
    @disks = Disk.paginate(:page => params[:page], per_page: 20)
  end

  def show
    @disk = Disk.find(params[:id])
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

  private

  def disk_params
    params.require(:disk).permit(:name, :disk_type)
  end
end
