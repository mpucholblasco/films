class DownloadsController < ApplicationController
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format.json? }
  
  def index
    @downloads_last_update = Download.get_last_update()
    @downloads_last_update = @downloads_last_update.in_time_zone(ActiveSupport::TimeZone.new("Europe/Madrid")) if @downloads_last_update
    @downloads = Download.paginate(:page => params[:page], per_page: 50).order(:filename) if @downloads_last_update
  end
  
  def store
    Download.transaction do
      Download.delete_all()
      params['_json'].each do |file|
        logger.info "Obtaining file info: #{file.inspect}"
        download = Download.new(:filename => file['filename'], :percentage => file['percentage'])
        begin
          download.save()
        rescue
          download.filename = file['filename'].encode('UTF-8', :invalid => :replace, :undef => :replace)
          download.save()
        end
      end
      Download.set_last_update()
    end
    
    respond_to do |format|
      format.json { render json: { :message => :ok } }
    end
  end
end
