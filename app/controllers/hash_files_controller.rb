require 'base64'

class HashFilesController < ApplicationController
  # We need to include this helper to use it in view
  helper ToolsHelper

  def index
    @hash_files = HashFile.paginate(:page => params[:page], per_page: 50).order(:id)
  end

  def show
    @hash_file = HashFile.find(params[:id])
  end

  def edit
    @hash_file = HashFile.find(params[:id])
  end

  def update
    @hash_file = HashFile.find(params[:id])
    logger.debug "Editing hash_file: #{@hash_file.attributes.inspect}"

    if @hash_file.update(hash_file_params)
      redirect_to params[:link_to_back].nil? ? @hash_file : Base64.decode64(URI.decode(params[:link_to_back]))
    else
      render 'edit'
    end
  end

  def destroy
    @hash_file = HashFile.find(params[:id])
    @hash_file.destroy

    redirect_to hash_files_path
  end

  private

  def hash_file_params
    params.require(:hash_file).permit(:score, :link_to_back)
  end
end
