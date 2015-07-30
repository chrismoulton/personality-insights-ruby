#
# Copyright IBM Corp. 2014
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'sinatra'
require 'json'
require 'excon'
require './config/i18n.rb'


configure do
  service_name = "personality_insights"

  set :public_folder, 'public'

  endpoint = Hash.new

  set :endpoint, "<service_url>"
  set :username, "<service_username>"
  set :password, "<service_password>"

  if ENV.key?("VCAP_SERVICES")
    services = JSON.parse(ENV["VCAP_SERVICES"])
    if !services[service_name].nil?
      credentials = services[service_name].first["credentials"]
      set :endpoint, credentials["url"]
      set :username, credentials["username"]
      set :password, credentials["password"]
    else
      puts "The service #{service_name} is not in the VCAP_SERVICES, did you forget to bind it?"
    end
  end

  # Add a trailing slash, if it's not there
  unless settings.endpoint.end_with?('/')
    settings.endpoint = settings.endpoint + '/'
  end

  puts "endpoint = #{settings.endpoint}"
  puts "username = #{settings.username}"
end


get '/' do
  set_locale(request)
  erb :index
end


post '/' do
  @text = params[:text]
  @language = params[:language]

  begin
    return getProfile(@text, @language, I18n.locale)
  rescue Exception => e
    @error = 'Error processing the request, please try again later.'
    puts  e.message
    puts  e.backtrace.join("\n")
    return @error
  end

  erb :index
end


helpers do

  # Create a job
  def getProfile(data, language, locale)
    response = Excon.post(settings.endpoint + "api/v2/profile",
                          :body => data,
                          :headers => { 
                            "Content-Type" => "text/plain",
                            "Content-Language" => language,
                            "Accept-Language" => locale
                          },
                          :user => settings.username,
                          :password => settings.password)

    response.body
  end

  # Create a job
  def getVisualization(data)
    response = Excon.post(settings.endpoint + "api/v2/visualize?w=900&h=900&imgurl=/images/app.png",
                          :body => data,
                          :headers => { "Content-Type" => "application/json" },
                          :user => settings.username,
                          :password => settings.password)

    response.body
  end

  # Some of the trait names can be misunderstood by lay people,
  # make them a bit more approachable for the lay person
  def NAME_SUBST
    return {
      "Anger"=> "Fiery",
      "Anxiety"=> "Prone to worry",
      "Depression"=> "Melancholy",
      "Vulnerability"=> "Susceptible to stress",
      "Liberalism"=> "Authority-challenging",
      "Morality"=> "Uncompromising",
      "Friendliness"=> "Outgoing",
      "Neuroticism"=> "Emotional range"
    }
  end

  def flatten_systemu_traits(traits)
    arr = flatten_level(traits, 0)
    return arr
  end


  # transform a traits tree in a list and format the value to: ##.#%
  def flatten_level(t, level)
    arr = []
    if (level > 0 && ((not t.has_key?('children')) || level != 2))

      obj = { 'id' => t['name'] }
      if NAME_SUBST().has_key?(t['name'])
        obj['id'] = NAME_SUBST()[t['name']]
      end

      obj['title'] = t.has_key?('children')
      if t.has_key?('percentage')
        obj['value'] = (t['percentage'] * 100).floor.to_s + "%"
      end
      arr.push(obj)
    end
    if t.has_key?('children') && t['id'] != "sbh"
      t['children'].each do |child|
        arr.push(flatten_level(child, level + 1))
      end
    end
    return arr.flatten
  end

end