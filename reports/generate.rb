#!/usr/bin/ruby

require "rubygems"
require "bundler/setup"
require "gruff"
require "csv"
#require "mongo"

#@db = Mongo::Connection.new.db("networkreports")

def read_log(lines=nil)
  lines ||= preprocess
  lines.each_with_index.collect do |line, i|
    result = {}
    if line.start_with? "D, "
      result[:date] = parse_date line

      if lines[i+2].start_with? "---"
        result[:host] = parse_host lines[i+2]

        r = lines[i+3].split(",")
        result[:data] = {
          :transmited => parse_int(r[0]),
          :received => parse_int(r[1]),
          :loss => parse_loss(r[2]),
          :round_trip => parse_rt(lines[i+4], 1),
          :round_trip_stddev => parse_rt(lines[i+4], 2)
        }
      else
        result[:data] = {
          :transmited => 0,
          :received => 0,
          :loss => 100.0,
          :round_trip => 0,
          :round_trip_stddev => 0
        }
      end
    end

    result
  end.reject { |i| i == {} }
end

def avg_per_day(data)
  report_loss = {}
  report_rt = {}

  data.each do |d|
    date = Date.parse(d[:date].to_s)
    report_loss[date] ||= []
    report_rt[date] ||= []
    report_loss[date] << d[:data][:loss]
    report_rt[date] << d[:data][:round_trip]
  end

   report_loss.each do |k,v|
     report_loss[k] = v.reduce(:+) / v.size.to_f
   end
   
   report_rt.each do |k,v|
     report_rt[k] = v.reduce(:+) / v.size.to_f
   end

  return [report_loss, report_rt]
end

def generate_csv(name, data)
 report = StringIO.new

  CSV::Writer.generate(report, ',') do |line|
    line << ["Hora", "Packet loss (%)", "Round trip (ms)"]
    data.each do |d|
      line << [d[:date].to_s, d[:data][:loss], d[:data][:round_trip]]
    end
  end

  report.rewind 
  File.open(name, 'w') { |f| f.write(report.read) }
end

def generate_csv_per_day(name, data)
  loss, rt = avg_per_day(data)
  report = StringIO.new

  data = {}
  loss.each { |k,loss| data[k] = [loss, rt[k]] }

  CSV::Writer.generate(report, ',') do |line|
    line << ["Date", "Packet loss (%)", "Round trip (ms)"]
    data.each do |date, val|
      line << [date.strftime('%d/%m/%Y'), val.first, val.last]
    end
  end

  report.rewind 
  File.open(name, 'w') { |f| f.write(report.read) }
end

def parse_host(line)
  line.scan(/-{3}\s(.*?)\s-{3}/)[0][0].split(" ").first
end

def parse_loss(line)
  line.scan(/^(.*?)%/).first.first.to_f
end

def parse_int(line)
  line.scan(/^\s*(\d+)/).first.first.to_i
end

def parse_rt(line, pos=1)
  line.split("=").last.split("/")[pos].to_f
end

def parse_date(line)
  DateTime.parse line.scan(/\[(.*?)\]/).first.first
end

def plot_graph(data, serie_name)
  g = Gruff::Line.new
  # Transforming array into hash
  g.labels = Hash[data.collect { |d| [data.index(d), d.to_s] }]
  g.data(serie_name, data.values )

  return g
end

def preprocess(fpath="monitor.log")
  File.open(fpath, "r") do |f|
    f.lines.reject do |line|
      line.start_with?("64") ||
        line.start_with?("PING") ||
        line.start_with?("Request timeout") ||
        line.start_with?("#")
    end
  end
end
