Application to test the Bluemix integration with IBM alternative solution for AWS S3: IBM Object Storage.
=========================================================================================================

Uplading files to object storage
================================

When you deploy your app into a PaaS and the app
should allow the user to upload files into the server
you can not use the instance local storage because
instances are disposable so the sotrage is efemeral.

http://docs.cloudfoundry.org/concepts/architecture/warden.html

Given that, I'm going to show you how to solve that problem developing
a simple app as an example, we will use Object Storage to store our
binary files, the service offers a free plan where we can upload up to 5gb.

https://console.ng.bluemix.net/docs/services/ObjectStorage/index.html

For this post the app that we will develop is very simple,
is a form where the user can upload any binary file, a document, an image,
etc. under a "directory" (a container) and then list the documents
under certaint directory. There will be 3 existing directories:
"Music", "Images", "Docs".

IBM Object storage overview.
============================

IBM object storage is build upon swift , that is anobject/blob store,
the API architecture is very similar to Amazon s3, in s3 you have
buckets and objects and in swift you have  containers instead of buckets.

http://docs.openstack.org/developer/swift/api/object_api_v1_overview.html

Here you have some API endpoints:

In fact there is and endpoints to list the available endpoints :).

`GET /v1/endpoints`

Show container details and list objects.

`GET /v1/{account}/{container}`

Get object content and metadata.

`GET /v1/{account}/{container}/{object}`

Create or replace object.

`/v1/{account}/{container}/{object}`

Delete object.

`DELETE /v1/{account}/{container}/{object}`

OK, I just showed these endpoints to have an idea about how the API works.

Creating the app.
=================
As I said before, the app will have 2 endpoints, one for upload a file under a
certain "directory" and other for list the files, here I put the mockups:

![Upload mockup](https://raw.githubusercontent.com/Altoros/bluemix-object-store-example/master/img/upload_mockup.jpg)

![Files List mockup](https://raw.githubusercontent.com/Altoros/bluemix-object-store-example/master/img/file_list_mockup.jpg)

Now lets start creating the basic files for our app, we will use cuba as in our previous [post]()
we need 4 files


```shell
app.rb
config.ru
Gemfile
views/upload.mote
```

**app.rb**


```shell
echo "require 'cuba'
require 'mote'
require 'mote/render'

Cuba.plugin Mote::Render

Cuba.define do

  on root do
    on get do
      render 'upload'
    end
  end
end" > app.rb
```

**config.ru**

```shell
echo "require './app'
run Cuba" > config.ru
```

**Genfile.rb**


```shell
echo "source 'https://rubygems.org'
gem 'cuba'
gem 'mote'
gem 'mote-render'
gem 'pry'" > Gemfile.rb
```

**views/upload.mote**


```shell
mkdir views
```

```shell
echo '<h1>Upload Your File</h1>

<form method="post" enctype="multipart/form-data" action="/">
  <fieldset>
    <select>
      <option value="music">Music</option>
      <option value="images">Images</option>
      <option value="docs">Documents</option>
    </select>

    <input name="file" type="file">
    <br /><br />
    <button type="submit">Upload</button>
  </fieldset>
</form>' > views/upload.mote
```
Now install the required gems:

`bundle install`

and if we run the `rackup` command and open
a browser in http://localhost:9292 we should see
our upload form. But it does nothing, we will
add a new endpoint to handle the POST request
after the user clicks in the upload button,
but before this lets add Service Open Storage in Bluemix dashboard
as descripted in the [documentation](https://console.ng.bluemix.net/docs/services/ObjectStorage/index.html).

After this you can see the credentials in the bluemix dashboard in
the object storage service section, with that data we can test the
service using curl:

```shell
curl -i \
-H "Content-Type: application/json" \
-d '
{
  "auth": {
    "identity": {
      "methods": ["password"],
        "password": {
          "user": {
            "name": "Admin_username",
            "domain": { "id": "domain" },
            "password": "password"
          }
        }
     },
     "scope": {
       "project": {
         "name": "project",
         "domain": { "id": "domainId" }
        }
      }
     }
}' \
https://identity.open.softlayer.com/v3/auth/tokens ; echo

```
You can find more examples in openstack [documentation](http://developer.openstack.org/api-ref-identity-v3.html)

Now that we have tested the service and we are sure it works, we will start interacting with Object Storage, let's add the Swift Client gem in the Gemfile:

`gem 'swift_client'`

https://github.com/mrkamel/swift_client

Then create the containers in bluemix from dashboard by clicking the 'Add container' on menu 'Action', remember that our app will have 3 categories (containers),
Music, Images and Documents.

![add container](https://raw.githubusercontent.com/Altoros/bluemix-object-store-example/master/img/create-containers-screenshot.png)

Upload file endpoint.
=====================
First, we have to connect to a Swift cluster, let' s add a module for that purpose in
our app.rb file:

```ruby
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
```
Take atention over two things that I found in this,

* The auth_url needs to include /v3.
* The storage_url has to be like the service [documentacion](https://console.ng.bluemix.net/docs/services/ObjectStorage/index.html) describes.

Second, to add a new endpoint to handle the file upload, we have to add a new endpoint in our app.rb like this:

```ruby
on post do
    on root do
      OStorage.client.put_object(req['file'][:filename],
                                 req['file'][:tempfile], req['container'])
      res.redirect '/'
    end
  end
end
```

with this we are able to upload a file into a directory in the Object Storage,
but we also want to list the files under a certain directory, lets add
a new route under get, and entire app.rb will be like this:

```ruby
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
```

The upload view is like:

```html
<h1>Upload Your File</h1>
<form method="post" enctype="multipart/form-data"
      action="/" class="form-inline alert alert-info text-center">
  <label for="container">Container:</label>
  <select id="container" name="container">
    <option value="music">Music</option>
    <option value="images">Images</option>
    <option value="documents">Documents</option>
  </select>

  <label for="file">File:</label>
  <input name="file" type="file" class="form-control" id="file">
  <button type="submit" class="btn btn-primary">Upload</button>
</form>

<ul class="nav nav-pills nav-justified">
  <li role="presentation" class="active"><a href="/?container=music">Music</a></li>
  <li role="presentation"><a href="/?container=images">Images</a></li>
  <li role="presentation"><a href="/?container=documents">Documents</a></li>
</ul>

% files.each do |f|
  <a href="/file/{{ f['hash'] }}">
    {{ f['name'] }}
  </a>
  <form method="post" action="{{container}}/{{ f['name'] }}">
    <button type="submit">Delete</button>
  </form><br />
% end
<br/>
```



