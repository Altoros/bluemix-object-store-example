require 'cuba'
require 'mote'
require 'mote/render'
require 'swift_client'
require 'json'

Cuba.plugin Mote::Render

module OStorage
  def self.client
    o_storage   = JSON.parse ENV['VCAP_SERVICES']
    credentials = o_storage['Object-Storage'].first['credentials']

    SwiftClient.new(
      :auth_url          => "#{ credentials['auth_url'] }/v3",
      :username          => credentials['username'],
      :password          => credentials['password'],
      :domain_id         => credentials['domainId'],
      :project_name      => credentials['project'],
      :project_domain_id =>  credentials['domainId'],
      :storage_url       => "https://dal.objectstorage.open.softlayer.com/v1/AUTH_#{ credentials['projectId'] }"
)
  end
end

Cuba.define do

  on root do

    on get do
      render 'upload'
    end

    on post do

#      require 'pry' ; binding.pry
      OStorage.client.put_object(req['file'][:filename], req[:tempfile], req['container'])
      res.redirect '/'
    end
  end
end
