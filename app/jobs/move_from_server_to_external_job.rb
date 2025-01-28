require "fileutils"

class MoveFromServerToExternalJob < ApplicationJob
  SOURCE_PATH = "/home/marcel/.aMule/Incoming/"
  MOUNT_PATH = "/media/usb"
  TARGET_PATH = "#{MOUNT_PATH}/procesar/"
  queue_as :copy_from_server_to_external

  def max_run_time
    24 * 3600 # 1 day
  end

  before_enqueue do |job|
    logger.debug "Initializing job MoveFromServerToExternalJob progress with job: #{job.inspect}"
    job_progress = Job.new
    job_progress.description = I18n.t(:move_from_server_to_external_job_description)
    job_progress.id = job.job_id
    job_progress.progress_max = 100
    job_progress.save()
  end

  after_perform do |job|
    logger.info "MoveFromServerToExternalJob #{job_id} finished correctly"
    job_progress = Job.find(job_id)
    job_progress.upgrade_progress(100, I18n.t(:update_content_finish))
    job_progress.finish_correctly
    system("sync")
  end

  rescue_from(StandardError) do |exception|
    logger.info "MoveFromServerToExternalJob #{job_id} raised exception: #{exception.inspect}"
    job_progress = Job.find(job_id)
    job_progress.upgrade_progress(100, "Error")
    job_progress.finish_with_errors(exception.message)
    system("sync")
  end

  def perform(*args)
    logger.debug "Performing MoveFromServerToExternalJob with job id = #{job_id}"
    job_progress = Job.find(job_id)
    MoveFromServerToExternalJob.process(SOURCE_PATH, MOUNT_PATH, TARGET_PATH, job_progress)
  end

  def self.process(source_path, mount_path, target_path, job_progress)
    job_progress.upgrade_progress(0, I18n.t(:move_from_server_to_external_job_obtaining_info))
    files_to_move = self.obtain_files_to_move(source_path)

    max_progress_to_move = MoveFromServerToExternalJob.get_max_progress_to_move(files_to_move)
    processed_progress_to_move = 5
    moved_files = 0
    self.check_external_disk(mount_path)
    logger.info("Moving #{files_to_move.length} files from internal disk to external path: #{target_path}")
    Dir.mkdir(target_path) if not File.directory? target_path
    begin
      files_to_move.each do |file|
        break if job_progress.is_cancelled?
        basename = File.basename(file)
        logger.info("Gonna process basename #{basename}")
        logger.info("max_progress_to_move = #{max_progress_to_move}, processed_progress_to_move = #{processed_progress_to_move}, moved_files = #{moved_files}")
        job_progress.upgrade_progress(5 + (processed_progress_to_move * 95 / max_progress_to_move).floor, I18n.t(:move_from_server_to_external_job_moving_file, filename: basename) + ". " + I18n.t(:move_from_server_to_external_info_about_moved, moved_files: moved_files, total_files: files_to_move.length))
        target_filename = File.join(target_path, basename)
        processed_progress_to_move = processed_progress_to_move + File.stat(file).blocks
        begin
          logger.info("Moving file #{file} to #{target_filename}")
          FileUtils.mv(file, target_filename)
          logger.info("After moving file #{file} to #{target_filename}")
        rescue StandardError => e
          logger.info("Exception raised on file #{file}, with exception class '#{e.class}', message '#{e.message}' and backtrace #{e.backtrace}")
          File.unlink target_filename if File.exists?(target_filename)

          # Ignore the following errors: invalid argument (can not find origin file)
          raise e if not e.is_a? Errno::EINVAL
        end
        moved_files = moved_files + 1
      end
    rescue IOError, Errno::ENOSPC => ex
      raise StandardError.new(I18n.t(:move_from_server_to_external_full_disk) + ". " + I18n.t(:move_from_server_to_external_info_about_moved, moved_files: moved_files, total_files: files_to_move.length) + ". Original message: " + ex.message)
    end
  end

  def self.check_external_disk(mount_path)
    begin
      disk = HardDiskInfo.read_from_mounted_disk(mount_path)
      disk.ensure_exists
      logger.info("Detected external disk: #{disk.inspect}")
    rescue StandardError => e
      logger.error("Couldn't obtain information from external disk. Error: #{e.inspect}")
      raise StandardError.new(I18n.t(:move_from_server_to_external_no_external_disk))
    end
  end

  def self.obtain_files_to_move(source_path)
    Dir.glob(File.join(source_path, "*")).select { |e| File.file? e }.sort
  end

  def self.get_max_progress_to_move(files)
    files.reduce(0) { |sum, e| sum + File.stat(e).blocks }
  end
end
