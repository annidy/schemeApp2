#!/usr/bin/ruby

require "rubygems"
require "json"
require 'net/http'
require 'uri'

schemeApps = File.expand_path('../schemeApps.json', __FILE__)
schemeApps2 = File.expand_path('../schemeApps2.json', __FILE__)

scheme = JSON.parse(IO.read(schemeApps))
new_scheme = JSON.parse(IO.read(schemeApps2))

if ARGV.size > 0
	case ARGV.shift
	when "update"
		`curl -o #{schemeApps} "https://ihasapp.herokuapp.com/api/schemeApps.json"`
		exit 0
	when "build"
		p "build..."
		add_scheme = []
		scheme.each {|sch, appids|
			if new_scheme.find {|x| x[0] == sch} == nil
				add_scheme.add([sch, appids])
			end
		}
		if add_scheme.size > 0
			new_scheme.concat(add_scheme)
			p "Concat #{add_scheme.size} new"
		end
	else
		p "Usage: #{File.basename(__FILE__)} {update|build}"
	end
end

def FetchId(appid)
	p "FetchId #{appid}"
	name = nil
	uri = URI.parse("http://itunes.apple.com/lookup?id=#{appid}&country=CN")
	response = Net::HTTP.get_response uri
	ret_json = JSON.parse(response.body)
	if ret_json["resultCount"] > 0
		name = ret_json["results"][0]["trackName"] 
		p "Success!"
	else
		p "Failed"
	end
rescue Timeout::Error
	p "Timeout"
rescue
	p "Exception!"
ensure
	return name
end
# 随机打乱，防止被屏蔽
new_scheme.shuffle!
new_scheme.collect! {|item|
	if item.size == 2 and item[1] != nil
		p "Process #{item[0]} #{item[1]}..."
		item[1].each{|appid|
			name = FetchId(appid)
			if name != nil
				item.push(name)
				break
			end
		}
	end
	item = item
}

new_scheme.sort! {|a, b| a[0] <=> b[0]}
# save my own
f = File.new(schemeApps2, "w+")
JSON.dump(new_scheme, f)
totoal = new_scheme.size
success = new_scheme.count {|x| x.size > 2}
p "Total #{totoal}, successd #{success}"