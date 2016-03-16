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

Cuba.use Rack::Static,
         urls: %w[/js /css /img],
         root: File.expand_path("./public", __dir__)

Cuba.define do

  on get do
    on root do
      container = req.params['container'] || 'music'
      files = OStorage.client.get_objects(container).parsed_response

      render 'upload', container: container, files: files
    end
  end

  on post do
    on root do
      OStorage.client.put_object(req['file'][:filename],
                                 req['file'][:tempfile], req['container'])
      res.redirect '/'
    end

    on ':container/:filename' do |container, filename|
      OStorage.client.delete_object(filename, container)
      res.redirect '/'
    end

  end

end
