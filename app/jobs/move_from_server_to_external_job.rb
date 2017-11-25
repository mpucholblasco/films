require 'fileutils'
require 'shellwords'

class MoveFromServerToExternalJob < ActiveJob::Base
  SOURCE_PATH = '/home/marcel/.aMule/Incoming/'
  TARGET_PATH = '/media/usb/procesar/'
  queue_as :copy_from_server_to_external

  before_enqueue do |job|
    logger.debug "Initializing delayed MoveFromServerToExternalJob progress with job: #{job.inspect}"
    job_progress = DelayedJobProgress.new
    job_progress.description = I18n.t(:move_from_server_to_external_job_description)
    job_progress.job_id = job.job_id
    job_progress.progress_max = 100
    job_progress.save()
  end

  after_perform do |job|
    logger.info "MoveFromServerToExternalJob #{job_id} finished correctly"
    job_progress = DelayedJobProgress.find(job_id)
    job_progress.upgrade_progress(100, I18n.t(:update_content_finish))
    job_progress.finish_correctly
  end

  rescue_from(StandardError) do |exception|
    logger.info "MoveFromServerToExternalJob #{job_id} raised exception: #{exception.inspect}"
    job_progress = DelayedJobProgress.find(job_id)
    job_progress.upgrade_progress(100, "Error")
    job_progress.finish_with_errors(exception.message)
  end

  def perform(*args)
    # Do something later
    logger.debug "Performing MoveFromServerToExternalJob with job id = #{job_id}"
    job_progress = DelayedJobProgress.find(job_id)
    MoveFromServerToExternalJob.process(SOURCE_PATH, TARGET_PATH, job_progress)
  end

  def self.process(source_path, target_path, job_progress)
    job_progress.upgrade_progress(0, I18n.t(:move_from_server_to_external_job_obtaining_info))
    files_to_move = self.obtain_files_to_move(source_path)

    max_progress_to_move = MoveFromServerToExternalJob.get_max_progress_to_move(files_to_move)
    processed_progress_to_move = 5
    moved_files = 0
    logger.info("Moving #{files_to_move.length} files from internal disk to external path: #{target_path}")
    Dir.mkdir(target_path) if not File.directory? target_path
    begin
      files_to_move.each do |file|
        basename = File.basename(file)
        job_progress.upgrade_progress(5 + (processed_progress_to_move * 95 / max_progress_to_move).floor, I18n.t(:move_from_server_to_external_job_moving_file, :filename => basename) + ". " + I18n.t(:move_from_server_to_external_info_about_moved, :moved_files => moved_files, :total_files => files_to_move.length))
        target_filename = File.join(target_path, basename)
        begin
          logger.info("Moving file #{file} to #{target_filename}")
          FileUtils.mv(file.shellescape, target_filename)
        rescue IOError => e
          File.unlink target_filename
          raise e
        end
        processed_progress_to_move = processed_progress_to_move + File.stat(file).blocks
        moved_files = moved_files + 1
      end
      system("sync")
    rescue IOError => ex
      system("sync")
      raise StandardError.new(I18n.t(:move_from_server_to_external_full_disk) + ". " + I18n.t(:move_from_server_to_external_info_about_moved, :moved_files => moved_files, :total_files => files_to_move.length) + ". Original message: " + ex.message)
    end
  end

  def self.obtain_files_to_move(source_path)
    Dir.glob(File.join(source_path, '*')).select{ |e| File.file? e }
  end

  def self.get_max_progress_to_move(files)
    files.reduce(0) { |sum, e| sum + File.stat(e).blocks }
  end
end
