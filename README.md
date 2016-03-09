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
"General", "Personal", "Important".

IBM Object storage overview.
============================

IBM object storage is build upon swift , that is a object/blob store
the API architecture is very similar to Amazon s3, in s3 you have
buckets and objects and in swift you have  containers instead of buckets.

http://docs.openstack.org/developer/swift/api/object_api_v1_overview.html

Here you have some API endpoints:

In fact there is and endpoints to list the available endpoints :).

```GET /v1/endpoints```

Show container details and list objects.

```GET /v1/{account}/{container}```

Get object content and metadata.

```GET /v1/{account}/{container}/{object}```

Create or replace object.

```/v1/{account}/{container}/{object}```

Delete object.

```DELETE /v1/{account}/{container}/{object}```

OK, I just showed these endpoints to have an idea about how the API works,
But for this we will use the ruby binding library for open stack:
https://github.com/ruby-openstack

Creating the app.
=================
