require 'logger'

@global_opts = {
  :log => 'monitor.log',
  :results => 'results',
  :default_host => 'www.google.com.br'
}

def logger(opts = {})
  opts = @global_opts.merge(opts)
  log = Logger.new(opts[:log])
end

def ping(host = nil)
  host ||= @global_opts[:default_host]
  result = `ping -c 10 #{host}`
end

logger.debug do
  "\n" + ping + "\n" + ping("www.yahoo.com.br")
end
