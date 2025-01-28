module ToolsHelper
  TYPES=[ "B", "KB", "MB", "GB", "TB" ]
  def get_human_size(size)
    size = size.to_f
    type = 0
    while size > 1024
      size /= 1024
      type += 1
    end
    sprintf("%g%s", (size * 10).ceil.to_f / 10, TYPES[type]) # we will only allow 1 decimal
  end
end
