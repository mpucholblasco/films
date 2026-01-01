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

    final_stderr = ""
    begin
      Open3.popen3(amulecmd_command) do |stdin, stdout, stderr, thread|
        stdin.close # close as no input is needed

        stdout_thread = Thread.new { stdout.read }
        stderr_thread = Thread.new { stderr.read }

        # Wait until process finishes
        status = thread.value

        final_stdout = stdout_thread.value
        final_stderr = stderr_thread.value

        Rails.logger.info("status=#{status}")

        Download.transaction do
          Download.delete_all()

          status = 0 # wait for a > with hash
          last_file_name = nil

          final_stdout.each_line do |line|
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
      Rails.logger.warn("Could not execute amulecmd command, ignoring. Error: #{e.inspect}. Stderr: #{final_stderr}")
    end
  end
end
