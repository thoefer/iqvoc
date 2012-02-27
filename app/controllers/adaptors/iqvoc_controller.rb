require "iqvoc/adaptors/iqvoc"

class Adaptors::IqvocController < ApplicationController
  
  respond_to :json
  
  def index
    authorize! :use, Iqvoc::Adaptors::Iqvoc
    
    adaptor = Iqvoc::Adaptors::Iqvoc.new(:iqvoc, "http://localhost:3001")
    response = adaptor.search(params[:query])
    render :json => response.body
  end
  
end