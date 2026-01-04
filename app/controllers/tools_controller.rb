class ToolsController < ApplicationController
  def index
  end

  def find_duplicated_movies
    logger.info "Finding duplicated movies"
    duplicated_movies = Rails.cache.fetch("duplicated_movies", expires_in: 10.minutes) do
      duplicated_movies = ActiveRecord::Base.connection.select_all(<<-SQL)
        SELECT d1.name AS fd1_disk_name, fd.fd1_disk_id, fd.fd1_filename, d2.name AS fd2_disk_name, fd.fd2_disk_id, fd.fd2_filename
        FROM (
          SELECT fd1.disk_id AS fd1_disk_id, fd1.filename AS fd1_filename, fd2.disk_id AS fd2_disk_id, fd2.filename AS fd2_filename
          FROM file_disks AS fd1
          INNER JOIN file_disks AS fd2 ON fd1.clean_title % fd2.clean_title AND fd1.id < fd2.id
          WHERE fd1.clean_title IS NOT NULL AND fd2.clean_title IS NOT NULL
          LIMIT 1000
        ) AS fd
        INNER JOIN disks AS d1 ON fd.fd1_disk_id = d1.id
        INNER JOIN disks AS d2 ON fd.fd2_disk_id = d2.id
      SQL
      duplicated_movies.to_a
    end

    @per_page = (params[:per_page] || 20).to_i
    @current_page = (params[:page] || 1).to_i

    @duplicates = Kaminari.paginate_array(duplicated_movies, total_count: duplicated_movies.size)
                          .page(@current_page)
                          .per(@per_page)
    logger.info "Found #{@duplicated_movies.size} duplicates"
  end

  def find_duplicated_series
    logger.info "Finding duplicated series"
    @duplicates = get_series_duplicates
    logger.info "Found #{@duplicates.size} series duplicated"
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
    job = MoveFromServerToExternalJob.perform_later
    logger.debug "Moving from server to external job with job info: #{job.inspect}"
    redirect_to job_path(job.job_id)
  end

  def copy_from_server_to_external_status
    job_id = params[:id]
    job_progress = Job.find(job_id)
    @progress = job_progress.progress
    logger.debug "Obtaining progress for job_id #{job_id}"
  end

  private

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
    series_found.reject { |k, v| v.length == 1 }
  end
end
