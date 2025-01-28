class Download < ApplicationRecord
  DOWNLOAD_UPDATE_STAT_NAME = "download"
  def self.search(search)
    scope = all
    if search
      search = search.strip
      if not search.empty?
        scope = search.split.permutation.map { |p| where("filename LIKE ?",
          "%" + p.map { |e| sanitize_sql_like(e) }.join("%") + "%")
        }.reduce { |scope, where| scope.or(where) }
      end
    end
    scope.order("filename")
  end

  def self.get_last_update
    update_stat = UpdateStat.select(:updated_at).find_by(name: DOWNLOAD_UPDATE_STAT_NAME)
    return update_stat.updated_at if update_stat
    nil
  end

  def self.set_last_update
    update_stat = UpdateStat.find_or_create_by(name: DOWNLOAD_UPDATE_STAT_NAME)
    update_stat.update_count += 1
    update_stat.save()
  end
end
