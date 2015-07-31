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

require 'excon'

# Personality Insights Service
class PersonalityInsights
  
  attr_accessor :endpoint, :username, :password
  
  def initialize(credentials)
    @endpoint = credentials["url"].end_with?("/") ? credentials["url"] : credentials["url"] + "/"
    @username = credentials["username"]
    @password = credentials["password"]
  end
  
  # Send a profile request to Personality
  # Insights service
  def profile(data, headers)
    # Set default headers
    headers[:contentType    ] ||= "text/plain"
    headers[:contentLanguage] ||= "en"
    headers[:acceptLanguage ] ||= "en"
    
    # Request the profile 
    response = Excon.post(@endpoint + "api/v2/profile",
                        :body     => data,
                        :headers  => { 
                          "Content-Type"     => headers[:contentType],
                          "Content-Language" => headers[:contentLanguage],
                          "Accept-Language"  => headers[:acceptLanguage]
                        },
                        :user     => @username,
                        :password => @password)
    
    response.body
  end
  
end