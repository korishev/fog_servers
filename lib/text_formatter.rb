require 'term/ansicolor'
require 'csv'
include Term::ANSIColor

class TextFormatter

  def initialize(options = {})
    @rows = []
    @write_csv = options.fetch(:write_csv) { false }
  end

  def tag_helper(tags)
    fixed_up = []
    tmp_tags = {}
    tags.sort.each do |tag|
      tag[1] = case tag[1]
               when "Supply Chain"
                 "SC".red.bold
               when "Store Front"
                 "SF".green.bold
               when "Price Sheet"
                 "PS".yellow.bold
               when "Forklift"
                 "FL".blue.bold
               when "VPC NAT"
                 "VN".white.bold
               when "Reporting"
                 "RP".magenta.bold
               when "Integration 1"
                 "I1"
               when "Integration 2"
                 "I2"
               when "getaroom-production"
                 "prod"
               else
                 tag[1]
               end
      tmp_tags[tag[0]] = tag[1]
    end

    tmp_tags.delete("Name")

    fixed_up << [tmp_tags.fetch("App") {nil}]; tmp_tags.delete("App")
    fixed_up << [tmp_tags.fetch("Role") {nil}]; tmp_tags.delete("Role")
    fixed_up << [tmp_tags.fetch("Chef Organization") {nil}]; tmp_tags.delete("Chef Organization")
    fixed_up << [tmp_tags.fetch("Created By") {nil}]; tmp_tags.delete("Created By")
    fixed_up

  end

  def zone_helper(zone)
    az = zone[-2..-1].upcase
    case az
    when "1A"
      "1A".blue.bold
    when "1B"
      "1B".magenta
    when "1C"
      "1C".cyan
    when "1D"
      "1D".white
    end
  end

  def colorize_state(state)
    case state
    when "running"
      state.green.bold
    else
      state.red.bold
    end
  end

  def server_table(servers)
    last_group = "none"
    servers.each do |server|
      @rows << [ server.attributes[:private_ip_address],
                ssh_link(server.attributes[:public_ip_address]),
                zone_helper(server.attributes[:availability_zone]),
                server.attributes[:id],
                server.attributes[:flavor_id],
                tag_helper(server.attributes[:tags]),
                server.attributes[:image_id],
                colorize_state(server.attributes[:state]),
                server.attributes[:created_at],
      ].flatten

    end
    @rows.sort! { |a,b| "#{a[5]} #{a[6]} #{a[3]}" <=> "#{b[5]} #{b[6]} #{b[3]}" }
  end

  def ssh_link(url)
    "ssh://#{url}"
  end

  def add_server_status(rows, statuses)
    rows.each do |row|
      instance_id = row[3]
      status = statuses.detect { |status| status["instanceId"] == instance_id }

      if status
        system_status = "#{status.fetch("systemStatus", {}).fetch("status", "") }"
        system_detail = "#{status.fetch("systemStatus", {}).fetch("details", {}).last.fetch("status")}"

        row << choose_status_color(system_status, "#{system_status} - #{system_detail}") unless status.nil?

        instance_status = "#{status.fetch("instanceStatus", {}).fetch("status", "") }"
        instance_detail = "#{status.fetch("instanceStatus", {}).fetch("details", {}).last.fetch("status")}"

        row << choose_status_color(system_status, "#{instance_status} - #{instance_detail}") unless status.nil?
      end
    end
  end

  def choose_status_color(system_status, message)
    case system_status
    when "ok"
      message.green
    else
      message.red
    end
  end

  def format(data)
    Term::ANSIColor::coloring = STDOUT.isatty && !@write_csv

    data.each do |env_name, servers, status|
      server_table(servers)
      add_server_status(@rows, status)
      headings = [ "Internal IP", "Public IP", "AZ", "Instance", "Flavor", "App", "Role", "Chef Env", "Owner", "Image", "State", "Created",  "SysStat", "InstStat" ]
      puts Terminal::Table.new :rows => @rows, :title => env_name, :headings => headings

      CSV.open("file_output", "wb", :headers => headings, :force_quotes => true, :write_headers => true) do |csv|
        @rows.each do |row|
          csv << row
        end
      end if @write_csv

    end
  end
end
