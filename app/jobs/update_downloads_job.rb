require "open3"

class UpdateDownloadsJob < ApplicationJob
  queue_as :update_downloads

  @@first_line_re = /^\s*>\s+(?<hash>[^\s]+)\s(?<filename>.+)$/
  @@second_line_re = /^\s*>\s+\[(?<percentage>[^%]+)%\].+/

  def perform(*args)
    amulecmd_command = <<~TEXT.squish
      #{Rails.configuration.settings.amule[:amulecmd]}
      -h #{Rails.configuration.settings.amule[:host]}
      -p #{Rails.configuration.settings.amule[:port]}
      -P #{Rails.configuration.settings.amule[:password]}
      -c 'show dl'
    TEXT

    Open3.popen3(amulecmd_command) do |stdout, stderr, status, thread|
      Rails.logger.info("status=#{status}") # TODO check status and filter

      Download.transaction do
        Download.delete_all()

        status = 0 # wait for a > with hash
        last_file_name = nil
        while line=stdout.gets do
          case status
          when 0
            match = @@first_line_re.match(line)
            if match
              raise StandardError.new("Found match for file but file is not empty") unless last_file_name.nil?
              last_file_name = match["filename"]
              status = 1
            end
          else
            match = @@second_line_re.match(line)
            if match
              raise StandardError.new("Found match for percentage but file is empty") if last_file_name.nil?
              last_file_name = last_file_name.encode("UTF-8", invalid: :replace, undef: :replace)

              Download.new(filename: last_file_name, percentage: match["percentage"]).save!

              last_file_name = nil
              status = 0
            end
          end
        end
        Download.set_last_update()
      end
    end
  rescue SystemCallError, StandardError => e
    Rails.logger.warn("Could not execute amulecmd command, ignoring. Error: #{e.inspect}")
  end
end
