class DownloadsController < ApplicationController
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format.json? }
  
  def index
    @downloads_last_update = Download.get_last_update().in_time_zone(ActiveSupport::TimeZone.new("Europe/Madrid"))
    @downloads = Download.paginate(:page => params[:page], per_page: 50).order(:filename) if @downloads_last_update
  end
  
  def store
    # TODO mpucholblasco : add store method
    logger.debug "Params: #{params.inspect}"
    
    Download.transaction do
      Download.delete_all()
      params['_json'].each do |file|
        logger.info "Obtaining file info: #{file.inspect}"
        Download.new(:filename => file['filename'], :percentage => file['percentage']).save()
      end
      Download.set_last_update()
    end
    
    respond_to do |format|
      format.json { render json: { :message => :ok } }
    end
  end
end
