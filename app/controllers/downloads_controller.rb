class DownloadsController < ApplicationController
  def index
    @downloads_last_update = Download.get_last_update()
    @downloads = Download.order(:filename).page params[:page] if @downloads_last_update
  end
end
