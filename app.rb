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
require './config/i18n.rb'
require './services/personalityinsights.rb'

configure do
  service_name = "personality_insights"

  set :public_folder, 'public'

  set :credentials, { 
    "url"      => "<service_url>",
    "username" => "<service_username>",
    "password" => "<service_password>"
  }

  if ENV.key?("VCAP_SERVICES")
    services = JSON.parse(ENV["VCAP_SERVICES"])
    if !services[service_name].nil?
      set :credentials, services[service_name].first["credentials"]
    else
      puts "The service #{service_name} is not in the VCAP_SERVICES, did you forget to bind it?"
    end
  end

  set :personality_insights, PersonalityInsights.new(settings.credentials)  
  
  puts "endpoint = #{settings.personality_insights.endpoint}"
  puts "username = #{settings.personality_insights.username}"
end


get '/' do
  set_locale(request)
  erb :index
end


post '/' do
  @text = params[:text]
  @language = params[:language]
  
  begin
    headers = {
      :contentLanguage => @language,
      :acceptLanguage  => I18n.locale
    }
    responseData = settings.personality_insights.profile(@text, headers)
  rescue Exception => e
    @error = I18n.t('error.requestProcessingError') + "."
    puts  e.message
    puts  e.backtrace.join("\n")
    responseData = @error
  end

  return responseData
end


