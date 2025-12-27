class FileDisk < ApplicationRecord
  @@filename_re = /^(?<filename>.+)\s\[(?<id>[^\]]+)\](\.(?<extension>[^.]+))?$/
  @@filename_ext_re = /^(?<filename>.+)\.(?<extension>[^.]+)$/

  belongs_to :disk
  attr_accessor :original_name
  before_save :fix_filename
  paginates_per 50
  broadcasts_refreshes

  def fix_filename
    self.filename = self.filename.encode("UTF-8", invalid: :replace, undef: :replace)
  end

  @original_name = nil

  def self.create_from_filename(filename, internal_filename, disk_id)
    file_disk = FileDisk.new
    file_disk.original_name = internal_filename
    file_disk.filename = internal_filename
    file_disk.size_mb = File.size(filename) / 1024 / 1024
    file_disk.disk_id = disk_id
    file_disk.deleted = false
    file_disk.id = self.get_id_from_filename(filename)
    file_disk
  end

  def self.get_id_from_filename(filename)
    filename = filename.encode("UTF-8", invalid: :replace, undef: :replace)
    filename_id_match = @@filename_re.match(filename)
    if filename_id_match
      return filename_id_match[:id].to_i(16)
    end
    nil
  end

  def self.find_using_filename_with_id(filename)
    id = self.get_id_from_filename(filename)
    if id
      begin
        return self.find(id)
      rescue ActiveRecord::RecordNotFound
      end
    end
    nil
  end

  def self.search(search)
    scope = where("deleted = false")
    if search
      search = FileDisk.sanitize_sql_like(search.strip)
      if not search.empty?
        likes = search.split.permutation.map { |p| where("filename ILIKE ?",
          "%" + p.map { |e| sanitize_sql_like(e) }.join("%") + "%")
        }.reduce { |scope, where| scope.or(where) }
        scope = scope.and(likes)
      end
    end
    scope.order("filename")
  end

  def append_id_to_filename
    if not self.id.nil? and not self.filename.nil? and not self.filename.empty?
      self.filename = self.filename.encode("UTF-8", invalid: :replace, undef: :replace)
      id_in_filename = " [#{self.id.to_s(16)}]"
      filename_id = @@filename_re.match(self.filename)
      if filename_id
        new_filename = filename_id[:extension].nil? ? "#{filename_id[:filename]}#{id_in_filename}" : "#{filename_id[:filename]}#{id_in_filename}.#{filename_id[:extension]}"
      else
        filename_extension_match = @@filename_ext_re.match(self.filename)
        if filename_extension_match
          new_filename = "#{filename_extension_match[:filename]}#{id_in_filename}.#{filename_extension_match[:extension]}"
        else # has no extension -> just append the ID
          new_filename = "#{self.filename}#{id_in_filename}"
        end
      end
      self.filename = new_filename
    end
  end

  def copy_extra_data(other)
    if other
      self.id = other.id
      self.score = other.score
    end
  end

  def copy_from_created_from_filename(other)
    if other
      self.original_name = other.original_name
      self.filename = other.filename
      self.size_mb = other.size_mb
      self.disk_id = other.disk_id
      self.deleted = other.deleted
    end
  end

  def ==(other)
    not other.nil? and
    other.id == self.id and
    other.filename == self.filename and
    other.size_mb == self.size_mb and
    other.disk_id == self.disk_id and
    other.score == self.score
  end
end
