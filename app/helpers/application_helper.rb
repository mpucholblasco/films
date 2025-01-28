module ApplicationHelper
  def nav_links
    items = [ disks_link, files_link, downloads_link, jobs_link, tools_link ]
    content_tag :nav do
      items.collect { |item| concat item }
    end
  end

  def disks_link
    nav_item_active_if current_page?(disks_path), t(:disks), controller: "disks"
  end

  def downloads_link
    nav_item_active_if current_page?(downloads_path), t(:downloads), controller: "downloads"
  end

  def files_link
    nav_item_active_if current_page?(files_path), t(:files), controller: "file"
  end

  def jobs_link
    nav_item_active_if current_page?(jobs_path), t(:jobs), controller: "jobs"
  end

  def tools_link
    nav_item_active_if current_page?(tools_path), t(:tools), controller: "tools"
  end

  def nav_item_active_if(condition, name, attributes)
    if condition
      a_class = "active"
    end
    link_to name, attributes, class: a_class
  end
end
