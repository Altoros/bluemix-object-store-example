require 'cuba'
require 'mote'
require 'mote/render'

Cuba.plugin Mote::Render

Cuba.define do

  on root do
    on get do
      render 'upload'
    end

    on post do

    end
  end
end
