require 'yaml'
require 'sys/filesystem'
include Sys

module TasksHelper
  class FileDiskInfo < FileDisk
    def self.create_from_filename(filename, internal_filename, disk_id)
      file_disk_info = FileDiskInfo.new
      file_disk_info.filename = internal_filename
      file_disk_info.size_mb = File.size(filename) / 1024 / 1024
      file_disk_info.disk_id = disk_id
      return file_disk_info
    end

    def ==(other)
      other.filename == self.filename and
      other.size_mb == self.size_mb
    end
  end

  class HardDiskFilesInfo
    PATHS_TO_PROCESS = [ "Peliculas", "Series", "procesar", "Incoming" ]

    def initialize(mount, disk_id, remove_no_hash = False)
      @mount = File.realpath(mount)
      @disk_id = disk_id
      @processed = false
      @files_to_remove = []
      @files_to_add = []
      @remove_no_hash = remove_no_hash
    end

    def get_files_to_remove
      process if not @processed
      return @files_to_remove
    end

    def get_files_to_add
      process if not @processed
      return @files_to_add
    end

    private

    def process
      files_on_db = {}
      Disk.find(@disk_id).file_disks.each do |file_disk|
        files_on_db[file_disk.filename] = file_disk
      end

      PATHS_TO_PROCESS.each do |path|
        files = Dir.glob("#{@mount}/#{path}/**/*").select{ |e| File.file? e }
        files.each do |file|
          internal_filename = file[(@mount.length+1)..-1]
          file_info = FileDiskInfo.create_from_filename(file, internal_filename, @disk_id)
          file_db_info = files_on_db[internal_filename]
          if file_db_info
            if file_info == file_db_info and (not @remove_no_hash or not file_db_info.hash_id.nil?)
              files_on_db.delete(internal_filename)
            else
              @files_to_remove << file_db_info
              @files_to_add << file_info
            end
          else
            @files_to_add << file_info
          end
        end
      end
      @files_to_remove.push(*files_on_db.values)
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
