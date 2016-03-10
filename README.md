Application to test the Bluemix integration with IBM alternative solution for AWS S3: IBM xObject Storage

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
is a form where the user can upload any file, a document or an image
under a "directory" (a container) and then list the documents
under certaint directory. There will be 3 existing directories:
"Music", "Images", "Docs".

IBM Object storage overview.
============================

IBM object storage is build upon swift , that is a object/blob store
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

OK, I just showed these endpoints to have an idea about how the API works,
But for this we will use the ruby binding library for open stack:

https://github.com/ruby-openstack

Creating the app.
=================
As I said before, the app will have 2 forms, one for upload a file under a
certain category and other for list the files, here I put the mockups:

![Upload mockup](https://raw.githubusercontent.com/Altoros/bluemix-object-store-example/master/img/upload_mockup.jpg)

![Files List mockup](https://raw.githubusercontent.com/Altoros/bluemix-object-store-example/master/img/file_list_mockup.jpg)

Now let's start creating the basic files for our app, we will use
cuba as in our previous [post]()
need 4 files

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

We need to install the required gems:

`bundle install`

and if we run the `rackup` command and open
a browser in http://localhost:9292 we should see
our upload form. But it does nothing, we will
add a new endpoint to handle the POST request
after the user clicks in the upload button.

We will start interacting with Object Storage,
let's add the Openstack gem in the Gemfile:

`gem 'openstack', '1.1.2'`



