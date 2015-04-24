require 'net/ssh'
require 'uri'



class NetworkerInterface

  def initialize
    @config = YAML::load_file('config.yml')
    @attributes = ""
    @restrictions = ""
    @server = @config['server']
    @password = @config['password']
    @user = @config['user']
  end



  def select(*attributes)
    @attributes = ""

    attributes = attributes.map { |attribute| attribute.to_s.downcase.gsub("_", " ") }
    attributes.each do |attribute|
      @attributes += " #{attribute};"
    end

    self
  end



  def where(attributes_hash)
    @restrictions = ""

    attributes_hash.each do |key, value|
      @restrictions += " #{key.to_s.downcase.gsub("_", " ")}: #{value};"
    end

    run_query
  end



  def all
    @restrictions = ""
    @attributes = ""
    run_query
  end



  private
  def run_query
    query = "show #{@attributes}\n\nprint #{@restrictions}\n\n"
    @restrictions = ""
    @attributes = ""
    command = "printf '#{query}' > networker_query &&  /usr/sbin/jobquery -i networker_query"
    response = ssh_cmd(command)
    parse_response(response)
  end
  
  
  def ssh_cmd(command)
    # Build shell command to run
    session = Net::SSH.start(@server, @user, password: @password, port: @port)
    response = session.exec!(command)
    session.close
    response
  end


  def parse_response(response)
    # Splitting on the double newline creates an array of substrings
    # Each substring describes a single job
    response = response.split("\n\n")

    # Splitting on the semicolon turns the substring describing a single job into
    # an array of substrings
    # Each substring in the job array contains a key/value pair
    # The attribute names (keys) and values are stored in the new job hash
    jobs = []
    response.each do |a_job|
      a_job.delete!("\n")
      job = Hash.new
      a_job.split(";").each do |attribute|
        k, v = attribute.split(":")
        v = v.to_s.strip.split(",              ").map(&:strip)
        v = v.join if v.length < 2
        job[k.strip.gsub(" ", "_").to_sym] = v
      end
      #Each job hash is added the array
      jobs.push(job)
    end

    jobs
  end
end