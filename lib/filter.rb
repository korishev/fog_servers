class Filter
  def initialize(filters)
    @filters = filters
  end

  def apply_to(servers)
    @filters.each do |filter|
      apply(filter, servers)
    end
    servers
  end

  def apply(filter, servers)
    servers[0][1].reject! do |server|
      key, value = filter.split(':')
      server.tags[key] != value
    end
  end
end
