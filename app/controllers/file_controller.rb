class FileController < ApplicationController
  def index
    @downloads_last_update = Download.get_last_update()
    @downloads = Download.search(params[:search]) if @downloads_last_update
    @files = FileDisk.search(params[:search]).page params[:page]
  end
end
