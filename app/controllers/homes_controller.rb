class HomesController < ApplicationController
  include RaptorParser

  def index
    @new_urls = current_user.url_lists.new
  end

  def show
    @list = current_user.url_lists.find(params[:id])
  end

  def create
    @url_list = current_user.url_lists.new(urls_params)
    convert_urls(@url_list)

    if @url_list.save
      flash.now[:notice] = 'Client was successfully created.'
      sidq_status = PdfWorker.perform_async(@url_list.urls)
      save_sidq_status(sidq_status)
    else
      flash.now[:error] = 'Error occurred while creating client.'
    end

    redirect_to homes_path(id: @url_list.id)
  end

  def pdf_metadata
    render json: parse_urls
  end

  private

  def urls_params
    params.require(:url_list).permit(
        :user_id, :urls)
  end

  def convert_urls(object)
    object[:urls] = object[:urls].gsub(/\n/, ' ').split(' ')
  end

  def save_sidq_status(sidq_status)
    job = SidekiqStatus.new(job_id: sidq_status, url_list_id: @url_list.id)
    job.save
  end

  def parse_urls
    uris = URI.parse(request.original_fullpath)
    uris = CGI.parse(uris.query)

    respond = []
    uris.each_with_index do |uri, index|
      uri[1].each do |url|
        begin
          raptor_api(url, create_pdf_name(url))
        rescue
          next
        end
      end
        respond << {"#{index+1}": create_raptor_json(uri[1])}
        respond << create_raptor_json(uri[1])
    end
    # TODO: need finish sorting and clean code
    # respond.sort_by { |e| e.each { |el| el[0][:info][:Title]} }

    respond
  end

  def create_raptor_json(urls)
    result = []
    begin
      urls.each do |url|
        reader = PDF::Reader.new("./tmp/#{create_pdf_name(url)}.pdf")
        result << {url: reader.pdf_version, pdf_version: reader.pdf_version, info: reader.info, "metadata": reader.metadata, "page_count": reader.page_count}
      end
    rescue
      result
    end
    result.sort_by{ |e| -e[:page_count] }
  end

  def create_pdf_name(url)
    url.gsub(/\W/, '')
  end

end
