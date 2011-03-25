require 'logger'

@global_opts = {
  :log => 'iperf.log',
  :results => 'results',
  :host => '',
  :port => "5001"
}

def logger(opts = {})
  opts = @global_opts.merge(opts)
  log = Logger.new(opts[:log])
end

def iperf(opts = {})
  opts = @global_opts.merge(opts)
  result = `iperf -c #{opts[:host]} -p #{opts[:port]}`
end

logger.debug do
  "\n" + iperf
end
