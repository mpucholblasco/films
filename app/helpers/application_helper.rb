module ApplicationHelper
  def nav_links
    items = [disks_link, files_link]
    content_tag :nav do
      items.collect { |item| concat item}
    end
  end

  def disks_link
    nav_item_active_if current_page?(disks_path), 'Disks', controller: 'disks'
  end

  def files_link
    nav_item_active_if current_page?(files_path), 'Files', controller: 'file'
  end

  def nav_item_active_if(condition, name, attributes)
    if condition
      a_class = "active"
    end
    link_to name, attributes, :class => a_class 
  end
end
