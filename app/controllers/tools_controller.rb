class ToolsController < ApplicationController
  def index
  end

  def find_duplicates
    logger.info "Finding duplicates"
    @duplicates = get_file_disk_duplicates
    logger.info "Found #{@duplicates.length} duplicates"
  end

  def find_series_duplicates
    logger.info "Finding series duplicated"
    @duplicates = get_series_duplicates
    logger.info "Found #{@duplicates.length} series duplicated"
  end

  def stop_amule
    begin
      `sudo service amule-daemon stop`
      @message = :server_stopped_correctly
    rescue
      @message = :server_stopped_error
    end
  end

  def start_amule
    begin
      `sudo service amule-daemon start`
      @message = :server_started_correctly
    rescue
      @message = :server_started_error
    end
  end
  
  def copy_from_server_to_external
    job = CopyFromServerToExternalJob.perform_later "This is a simple test"
    logger.debug "Added job with info #{job.inspect}"
    @job_id = job.job_id
  end
  
  def copy_from_server_to_external_status
    job_id = params[:id]
    job_progress = DelayedJobProgress.find(job_id)
    @progress = job_progress.progress
    logger.debug "Obtaining progress for job_id #{job_id}"
  end

  private

  def get_file_disk_duplicates
    filenames_found = {}
    FileDisk.find_each do |file_disk|
      if file_disk.filename !~ /^series/i
        basename = File.basename(file_disk.filename)
        if filenames_found.has_key?(basename)
        filenames_found[basename] << file_disk
        else
          filenames_found[basename] = [file_disk]
        end
      end
    end

    filenames_found.reject!{ |k,v| v.length == 1}
  end

  def get_series_duplicates
    series_found = {}
    r = Regexp.compile("^series\/([^\/]+)\/.*$", true)
    FileDisk.find_each do |file_disk|
      m = r.match(file_disk.filename)
      if m
        serie_name = m[1]
        if ! series_found.has_key?(serie_name)
          series_found[serie_name] = {}
        end
        serie_disk_info = series_found[serie_name]
        series_found[serie_name] = { file_disk.disk_id => 1 } if ! serie_disk_info.has_key?(file_disk.disk_id)
      end
    end
    series_found.reject!{ |k,v| v.length == 1}
  end
end
