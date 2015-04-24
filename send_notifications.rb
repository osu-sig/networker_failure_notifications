require_relative 'networker_interface'

if Mailman.new.send_notifications
  exit(0)
else
  exit(1)
end