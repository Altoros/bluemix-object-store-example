require 'cuba'
require 'mote'
require 'mote/render'
require 'swift_client'
require 'json'

Cuba.plugin Mote::Render

o_storage   = JSON.parse ENV['VCAP_SERVICES']
credentials = o_storage['Object-Storage'].first['credentials']

swift_client = SwiftClient.new(
  :auth_url          => "#{ credentials['auth_url'] }/v3",
  :username          => credentials['username'],
  :password          => credentials['password'],
  :domain_id         => credentials['domainId'],
  :project_name      => credentials['project'],
  :project_domain_id =>  credentials['domainId'],
  :storage_url       => "https://dal.objectstorage.open.softlayer.com/v1/AUTH_#{ credentials['projectId'] }"
)

puts swift_client.auth_token.inspect
puts swift_client.storage_url
puts swift_client.get_containers.inspect

Cuba.define do

  on root do
    on get do
      render 'upload'
    end

  end
end
