class Download < ActiveRecord::Base
  DOWNLOAD_UPDATE_STAT_NAME = 'download'
  def self.search(search)
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
    matches
  end
  
  def self.get_last_update()
    update_stat = UpdateStat.select(:updated_at).find_by(name: DOWNLOAD_UPDATE_STAT_NAME)
    return update_stat.updated_at if update_stat
    return nil
  end
  
  def self.set_last_update()
    update_stat = UpdateStat.find_or_create_by(name: 'download')
    update_stat.update_count += 1
    update_stat.save()
  end
end
