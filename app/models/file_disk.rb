class FileDisk < ActiveRecord::Base
  belongs_to :disk
  def self.search(search, page)
    if search and not search.strip.empty?
      @matches = where('filename like ?', "%#{search}%").order('filename')
    else
      @matches = all
    end
    @matches.paginate :per_page => 20,
    :page => page
  end
end
