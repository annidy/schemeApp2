#!/usr/bin/ruby

require "rubygems"
require "json"
require 'net/http'
require 'uri'

schemeApps = File.expand_path('../schemeApps.json', __FILE__)
schemeApps2 = File.expand_path('../schemeApps2.json', __FILE__)

if ARGV.size
	case ARGV.shift
	when "update"
		`curl -o #{schemeApps} "https://ihasapp.herokuapp.com/api/schemeApps.json"`
	else
		p "Usage: #{File.basename(__FILE__)} {update}"
	end
	exit 0
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

scheme = JSON.parse(IO.read(schemeApps))
new_scheme = JSON.parse(IO.read(schemeApps2))

if new_scheme
	add_scheme = []
	new_scheme.each {|item|
		sch = item[0]
		if not scheme.has_key?(sch)
			add_scheme.push([sch, scheme[sch]])
		end
	}
	if add_scheme.size > 0
		new_scheme.concat(add_scheme)
		p "Concat #{add_scheme.size} new"
	end

	new_scheme.shuffle!
	new_scheme.collect! {|item|
		if item.size < 3
			p "Process #{item[0]}..."
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
else
	scheme.shuffle!
	scheme.each {|sch, appids|
		item = [sch, appids]
		p "Process #{item[0]}.."
		appids.each {|appid|
			name = FetchId(appid)
			if name != nil
				item.push(name)
				break
			end
		}
		new_scheme.push(item)
	}
end

# save my own
f = File.new(schemeApps2, "w+")
JSON.dump(new_scheme, f)
totoal = new_scheme.size
success = new_scheme.count {|x| x.size > 2}
p "Total #{totoal}, successd #{success}"