class FileDisk < ActiveRecord::Base
  belongs_to :disk
  belongs_to :hash_file, class_name: 'HashFile', foreign_key: 'hash_id'
  def self.search(search, page)
    if search
      search = search.strip
      if not search.empty?
        #[TODO] improve permutation likes
        #[TODO] improve index for filename -> filename, id instead id, filename
        w = nil
        search.split.permutation { |p|
          if w
            w = w + " OR filename like '%#{p.join('%')}%'"
          else
            w = "filename like '%#{p.join('%')}%'"
          end
        }
        matches = where(w).order('filename')
      else
        matches = all
      end
    else
      matches = all
    end
    matches.paginate :per_page => 50, :page => page
  end
end
