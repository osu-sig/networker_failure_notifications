require_relative 'mailman'

mailman = Mailman.new

if mailman.send_failure_notifications && mailman.send_unresolved_notifications
  exit(0)
else
  exit(1)
end