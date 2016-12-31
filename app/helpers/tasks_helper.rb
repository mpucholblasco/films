require 'yaml'
require 'sys/filesystem'
include Sys

module TasksHelper
  class HardDiskFilesInfo
    PATHS_TO_PROCESS = [ "Peliculas", "Series", "procesar", "Incoming" ]

    def initialize(mount, disk_id = nil)
      @mount = File.realpath(mount)
      @disk_id = disk_id
      @processed = false
      @files_to_remove = []
      @files_to_add = []
      @files_to_update = []
    end

    def get_files_to_remove
      process_info if not @processed
      @files_to_remove
    end

    def get_files_to_add
      process_info if not @processed
      @files_to_add
    end

    def get_files_to_update
      process_info if not @processed
      @files_to_update
    end

    def process
      disk = nil
      errors = ''
      begin
        disk = TasksHelper::HardDiskInfo.read_from_mounted_disk(@mount)
        disk.ensure_exists
        @disk_id = disk.id if @disk_id.nil?
      rescue ActiveRecord::RecordNotFound
        raise Exception.new(I18n.t(:update_error_disk_not_in_db))
      rescue IOError
        raise Exception.new(I18n.t(:update_error_disk_information_not_found))
      end

      if disk.id != @disk_id
        raise Exception.new(I18n.t(:update_error_inserted_disk_is_not_updating_one, :inserted_disk => disk.id, :updating_disk => @disk_id))
      end

      process_info if not @processed

      # Mark deleted files as deleted
      FileDisk.transaction do
        Rails.logger.info "Going to delete <#{@files_to_remove.length}>"
        @files_to_remove.each do |file|
          file.deleted = true
          file.save
        end
      end

      Rails.logger.info "Going to add <#{@files_to_add.length}>"
      @files_to_add.each do |file|
        begin
          FileDisk.transaction do
            file.save
            file.append_id_to_filename
            file.save
            File.rename("#{@mount}/#{file.original_name}", "#{@mount}/#{file.filename}")
          end
        rescue IOError => ex
          errors << I18n.t(:update_error_couldnt_rename_file, :original_name => file.original_name, :target_name => file.filename) << '(' << ex.message << ')' << '\n'
        rescue ActiveRecord::RecordNotUnique
          errors << I18n.t(:update_error_duplicated_file, :duplicated_filename => file.filename) << '\n'
        end
      end

      Rails.logger.info "Going to update <#{@files_to_update.length}>"
      @files_to_update.each do |file|
        begin
          FileDisk.transaction do
            file.save
            File.rename("#{@mount}/#{file.original_name}", "#{@mount}/#{file.filename}") if file.original_name != file.filename
          end
        rescue IOException
          errors << I18n.t(:update_error_couldnt_rename_file, :original_name => file.original_name, :target_name => file.filename) << '\n'
        rescue ActiveRecord::RecordNotUnique
          errors << I18n.t(:update_error_duplicated_file, :duplicated_filename => file.filename) << '\n'
        end
      end

      disk_db = Disk.find(disk.id)
      disk_db.last_sync = Time.zone.now
      disk_db.total_size = disk.total_size
      disk_db.free_size = disk.free_size
      disk_db.save()

      if not errors.empty?
        raise Exception.new(errors)
      end
    end

    private

    def get_files_on_db
      files_on_db = {}
      Disk.find(@disk_id).file_disks.each do |file_disk|
        files_on_db[file_disk.filename] = file_disk
      end
      return files_on_db
    end

    def process_info
      files_on_db = get_files_on_db
      ids_updated = Set.new

      PATHS_TO_PROCESS.each do |path|
        files = Dir.glob("#{@mount}/#{path}/**/*").select{ |e| File.file? e }
        files.each do |file|
          internal_filename = file[(@mount.length+1)..-1]
          file_on_disk_db = files_on_db[internal_filename]
          file_info = FileDisk.create_from_filename(file, internal_filename, @disk_id)
          file_on_db = FileDisk.find_using_filename_with_id(internal_filename)

          if file_on_db
            file_info.copy_extra_data(file_on_db)
            files_on_db.delete(internal_filename)
            if file_info != file_on_disk_db
              file_info.append_id_to_filename
              @files_to_update << file_info
              ids_updated.add(file_info.id)
            end
          elsif file_on_disk_db
            file_info.copy_extra_data(file_on_disk_db)
            file_info.append_id_to_filename
            files_on_db.delete(internal_filename)
            @files_to_update << file_info
            ids_updated.add(file_info.id)
          else # not present neither on DB nor disk_DB -> it's new
            @files_to_add << file_info
          end
        end
      end
      @files_to_remove = files_on_db.values.select{ |file|
        not ids_updated.include?(file.id)
      }
      @processed = true
    end
  end

  class HardDiskInfo < Disk
    DEFAULT_FILE_NAME = 'info'
    def self.read_from_mounted_disk(mount)
      return self.read_from_yaml(File.join(mount,DEFAULT_FILE_NAME))
    end

    def self.read_from_yaml(filename)
      raise IOError.new("File <#{filename}> not found") if not File.exists?(filename)

      begin
        disk_info = YAML::load_file filename
      rescue Psych::SyntaxError
        return self.read_from_old_file(filename)
      end

      disk = HardDiskInfo.new
      disk.name = disk_info['name']
      disk.id = disk_info['id']

      # Obtain disk space
      stat_info = Filesystem.stat(filename)
      disk.total_size = stat_info.block_size * stat_info.blocks
      disk.free_size = stat_info.block_size * stat_info.blocks_free
      return disk
    end

    def self.read_from_old_file(filename)
      raise IOError.new("File <#{filename}> not found") if not File.exists?(filename)
      content = File.open(filename).read
      content.gsub!(/\r\n?/, "\n")
      content_lines = content.lines

      disk = HardDiskInfo.new
      line1_match =  /ID Disco:\s*(\d+)/.match(content_lines[0])
      raise SyntaxError.new("Incorrect info file format") if not line1_match
      disk.id = line1_match[1].to_i
      disk.name = content_lines[1].strip()

      # Obtain disk space
      stat_info = Filesystem.stat(filename)
      disk.total_size = stat_info.block_size * stat_info.blocks
      disk.free_size = stat_info.block_size * stat_info.blocks_free
      return disk
    end

    def initialize
      super
      self.disk_type = :HD
    end

    def store_on_mounted_disk(mount)
      store_as_yaml(File.join(mount,DEFAULT_FILE_NAME))
    end

    def store_as_yaml(filename)
      settings = { 'id' => id, 'name' => name}
      File.open(filename, "w") do |file|
        file.write settings.to_yaml
      end
    end

    def ensure_exists
      other_disk = Disk.find(id)
      raise "Disk <#{name}> does not match with existing one" if name != other_disk.name or disk_type != other_disk.disk_type
      self.created_at = other_disk.created_at
      self.updated_at = other_disk.updated_at
    end
  end
end
