module DisksHelper
  class HardDiskFilesUpdaterInfo
    def initialize(mount, disk_id)
      @mount = mount
      @disk_id = disk_id
      @files_to_add = []
      @files_to_update = []
      @ids_updated = Set.new
      @files_to_update = []
      @files_to_add = []
    end

    def get_files_to_add
      @files_to_add
    end

    def get_files_to_update
      @files_to_update
    end

    def get_files_to_remove
      @files_on_db ||= get_files_on_db
      @files_on_db.values.select { |file|
        not @ids_updated.include?(file.id)
      }
    end

    def add_file(file)
      @files_on_db ||= get_files_on_db
      raise Exception.new("File #{file} does not start by mount path #{@mount}") if !file.start_with?(@mount)

      internal_filename = file[(@mount.length+1)..-1]
      file_on_disk_db = @files_on_db[internal_filename]
      file_info = FileDisk.create_from_filename(file, internal_filename, @disk_id)
      file_on_db = FileDisk.find_using_filename_with_id(internal_filename)

      if file_on_db
        file_on_db.copy_from_created_from_filename(file_info)
        @files_on_db.delete(internal_filename)
        if file_info != file_on_disk_db
          file_on_db.append_id_to_filename
          @files_to_update << file_on_db
          @ids_updated.add(file_on_db.id)
        end
      elsif file_on_disk_db
        file_on_disk_db.copy_from_created_from_filename(file_info)
        file_on_disk_db.append_id_to_filename
        @files_on_db.delete(internal_filename)
        @files_to_update << file_on_disk_db
        @ids_updated.add(file_on_disk_db.id)
      else # not present neither on DB nor disk_DB -> it's new
        @files_to_add << file_info
      end
    end

    private

    def get_files_on_db
      files_on_db = {}
      Disk.find(@disk_id).file_disks.each do |file_disk|
        files_on_db[file_disk.filename] = file_disk
      end
      files_on_db
    end
  end

  class HardDiskInfo
    DEFAULT_FILE_NAME = "info"
    def self.read_from_mounted_disk(mount)
      self.read_from_yaml(File.join(mount, DEFAULT_FILE_NAME))
    end

    def self.read_from_yaml(filename)
      raise IOError.new("File <#{filename}> not found") if not File.exist?(filename)

      begin
        disk_info = YAML.load_file filename
      rescue Psych::SyntaxError
        return self.read_from_old_file(filename)
      end

      HardDiskInfo.new(disk_info["id"], disk_info["name"], filename)
    end

    def self.read_from_old_file(filename)
      raise IOError.new("File <#{filename}> not found") if not File.exist?(filename)
      content = File.open(filename).read
      content.gsub!(/\r\n?/, "\n")
      content_lines = content.lines

      line1_match = /ID Disco:\s*(\d+)/.match(content_lines[0])
      raise SyntaxError.new("Incorrect info file format") if not line1_match

      HardDiskInfo.new(line1_match[1].to_i, content_lines[1].strip(), filename)
    end

    attr_reader :id, :name, :total_size, :free_size

    def initialize(id, name, filesystem_path)
      @id = id
      @name = name

      # Obtain disk space
      stat_info = Sys::Filesystem.stat(filesystem_path)
      @total_size = stat_info.block_size * stat_info.blocks
      @free_size = stat_info.block_size * stat_info.blocks_free
    end

    def store_on_mounted_disk(mount)
      store_as_yaml(File.join(mount, DEFAULT_FILE_NAME))
    end

    def store_as_yaml(filename)
      File.open(filename, "w") do |file|
        file.write({ "id" => @id, "name" => @name }.to_yaml)
      end
    end

    def ensure_exists
      other_disk = Disk.find(@id)
      raise Exception.new(I18n.t(:update_error_disk_not_in_db)) if name != other_disk.name
    end
  end
end
