class TextFormatter

  # ASCII CODES FOR TERMINAL COLORS
  BOLD_RED        = "[1;31m"
  BOLD_GREEN      = "[1;32m"
  BOLD_YELLOW     = "[1;33m"
  BOLD_MAGENTA    = "[1;35m"
  BOLD_CYAN       = "[1;36m"
  NORMAL_RED      = "[0;31m"
  NORMAL_GREEN    = "[0;32m"
  NORMAL_YELLOW   = "[0;33m"
  NORMAL_MAGENTA  = "[1;35m"
  NORMAL_CYAN     = "[1;36m"
  NORMAL_WHITE    = "[1;37m"
  RESET           = "[0m"

  def colorize_output(text, color)
    output = ""
    output << color if STDOUT.tty?
    output << text
    output << RESET if STDOUT.tty?
    output
  end

  def initialize
    @rows = []
  end

  def tag_helper(tags)
    fixed_up = []
    tags.sort.each do |tag|
      tag[1] = case tag[1]
               when "Supply Chain"
                 colorize_output("SC", BOLD_RED)
               when "Store Front"
                 colorize_output("SF", BOLD_GREEN)
               when "Forklift"
                 colorize_output("FL", BOLD_YELLOW)
               when "Integration 1"
                 "I1"
               when "Integration 2"
                 "I2"
               else
                 tag.last
               end

      fixed_up << tag.last unless tag.first == "Name"
    end
    fixed_up
  end

  def zone_helper(zone)
    color = NORMAL_WHITE
    az = zone[-2..-1].upcase
    color = case az
         when "1A"
           NORMAL_RED
         when "1B"
           NORMAL_GREEN
         when "1C"
           NORMAL_YELLOW
         when "1D"
           NORMAL_MAGENTA
         end
    colorize_output(az, color)
  end

  def colorize_state(state)
    case state
    when "running"
      colorize_output(state, BOLD_GREEN)
    else
      colorize_output(state, BOLD_RED)
    end
  end

  def server_table(servers)
    last_group = "none"
    servers.each do |server|
      @rows << [server.attributes[:private_dns_name],
                server.attributes[:private_ip_address],
                ssh_link(server.attributes[:public_ip_address]),
                zone_helper(server.attributes[:availability_zone]),
                server.attributes[:id],
                tag_helper(server.attributes[:tags]),
                server.attributes[:image_id],
                colorize_state(server.attributes[:state]),
               ].flatten

    end
        @rows.sort! { |a,b| "#{a[5]} #{a[6]} #{a[3]}" <=> "#{b[5]} #{b[6]} #{b[3]}" }
  end

  def ssh_link(url)
    "ssh://#{url}"
  end

  def format(data)
    data.each do |env_name, servers|
      server_table(servers)
      puts Terminal::Table.new :rows => @rows, :title => env_name, :headings => [ "Internal", "Internal IP", "Public IP", "AZ", "Instance", "App" ,"Role", "Image", "State" ]
    end
  end
end
