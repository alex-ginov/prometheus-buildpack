
#!/usr/bin/env ruby

require "erb"
require "json"
require "yaml"
require "fileutils"

def scrape_configs
  prometheus_scrape_configs = ENV["PROMETHEUS_SCRAPE_CONFIGS"] || []
  return JSON.parse(prometheus_scrape_configs)
end

content = File.read "/app/prometheus.yml.erb"
erb_conf = ERB.new(content)
erb_conf.run
