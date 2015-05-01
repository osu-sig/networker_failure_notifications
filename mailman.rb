require 'mail'
require_relative 'networker_interface'


class Mailman < NetworkerInterface
  def initialize
    super
    @host_email_mappings = get_host_email_mappings
    @hours_back_to_check = 8
    Mail.defaults do
      delivery_method :smtp, address: "smtp.oregonstate.edu", port: 587
    end
  end
  
  
  def send_notifications
    notifications = Hash.new([])
    get_failures.each do |host|
      email = @host_email_mappings[host]
      notifications[email] += [host].flatten
    end

    notifications.each do |email, hosts|
      puts "Notifying #{email} of #{hosts.length} failures: #{hosts.join(',')}"
      body = "Backups failed on the following hosts:\n" + hosts.join("\n")
      body += "\n\n\nPlease consider investigating."
      deliver(email, body)
    end
    
    true
  end
  
  
  
  private
  
  def get_mappings
    mappings = []
    File.open('./email_list_data.csv').read.split("\n").each do |entry|
      entry = entry.split(",")
      mappings << { host: entry[0], period: entry[1], group: entry[2], email: entry[3] }
    end
    mappings
  end
  
  
  def get_host_email_mappings
    mapped_hosts = Hash.new
    get_mappings.each do |entry|
      mapped_hosts[entry[:host]] = entry[:email]
    end
    mapped_hosts
  end
  
  
  def deliver(email_address, email_body)   
    Mail.deliver do 
      from 'sig.do_not_reply@onid.oregonstate.edu'
      to [email_address, 'gaylon.degeer@oregonstate.edu']
      subject 'Backup failure notification'
      body email_body
    end
  end
  
  
  def get_failures
    time_threshold = Time.now.to_i - @hours_back_to_check * 3600 + 60
    job_list = select(:end_time, :Reason_job_was_terminated, :failed_clients_list).
               where(type: 'savegroup job', job_state: 'COMPLETED', completion_status: 'failed')
    job_list.delete_if { |job| job[:Reason_job_was_terminated] == "Aborted" }
    job_list.delete_if { |job| job[:end_time].to_i < time_threshold }
    job_list.map { |job| job[:failed_clients_list] }.flatten
  end
  
end