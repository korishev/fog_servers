require 'erb'

class HTMLFormatter
  def initialize
    @template = ""
  end

  def group_header(env_name)
    template = "<thead><tr><td><%= env_name %></td></tr></thead>"
    template << "<tr><td>id</td><td>internal dns/ip</td><td>public dns/ip</td><td>tags</td></tr>"
    @template << ERB.new(template).result(binding)
  end

  def tag_helper(tags)
    fixed_up = []
    tags.sort.each do |tag|
      fixed_up << tag.join(":")
    end
    fixed_up.join(", ")
  end

  def row(server)
    template =  "<tr>"
    template << "<td><%= server.attributes[:id] %></td>"
    template << "<td><a href='ssh://<%=server.attributes[:private_dns_name]%>'><%=server.attributes[:private_dns_name]%></a></td>"
    template << "<td><a href='ssh://<%= server.attributes[:dns_name]%>'><%= server.attributes[:dns_name]%></a></td>"
    template << "<td><%= tag_helper(server.attributes[:tags]) %></td>"
    template << "</tr>"
    template << "<tr>"
    template << "<td></td>"
    template << "<td><%= server.attributes[:private_ip_address] %></td>"
    template << "<td><%= server.attributes[:public_ip_address] %></td>"
    template << "<td><span id='<%= server.attributes[:id]%>' class='json' ><%= server.attributes.to_json %></span></td>"
    template << "</tr>"
    @template << ERB.new(template).result(binding) if server.attributes[:state] == "running"
  end

  def format(data)
    document_header
    iterate_over_environments(data)
    document_footer
    puts @template
  end

  def iterate_over_environments(data)
    data.each do |env_name, servers|
      group_header env_name
      servers.each do |server|
        row server
      end
    end
  end

  def document_header
    template = ""
    template << "<html lang=en>"
    template << "<head><%= css %></head>"
    template << "<body>"
    template << "<table>"
    @template << ERB.new(template).result(binding)
  end

  def document_footer
    template = ""
    template << "</table>"
    template << "<body>"
    template << "</html>"
    @template << ERB.new(template).result(binding)
  end

  def javascript

  end

  def css
    @style =  "<style>"
    @style << ".json { display: none; }"
    @style << "</style>"
  end
end
