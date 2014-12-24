require 'yaml'

module TasksHelper
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
    
    def update_files_information(mount)
      files = Dir.glob("#{mount}/**/*").select{ |e| File.file? e }
      files.each do |f|
        puts "File found: #{f}"
      end
    end
  end
end
