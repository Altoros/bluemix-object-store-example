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

Now install the required gems:

`bundle install`

and if we run the `rackup` command and open
a browser in http://localhost:9292 we should see
our upload form. But it does nothing, we will
add a new endpoint to handle the POST request
after the user clicks in the upload button.

Then let's add Service Open Storage in Bluemix dashboard
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

Then we add the containers in bluemix from dashboard by clicking the 'Add container' on menu 'Action'.

![add container](https://raw.githubusercontent.com/Altoros/bluemix-object-store-example/master/img/create-containers-screenshot.png)



