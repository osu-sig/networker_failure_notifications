require_relative 'mailman'

if Mailman.new.send_notifications
  exit(0)
else
  exit(1)
end