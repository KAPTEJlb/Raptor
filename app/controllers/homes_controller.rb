# frozen_string_literal: true

class HomesController < ApplicationController
  include RaptorParser

  def index
    @new_urls = current_user.url_lists.new
  end

  def show
    @list = current_user.url_lists.find(params[:id])
    show_js if request.format.symbol == :js
  end

  def create
    @url_list = current_user.url_lists.new(urls_params)
    convert_urls(@url_list)

    save_url_list
    redirect_to homes_path(id: @url_list.id)
  end

  def pdf_metadata
    render json: parse_urls
  end

  def download_pdf
    link = remove_sum(params[:link])
    link.gsub!(/\..*/, '')
    file_path = Rails.root.join('tmp', 'pdfs', "#{link}.pdf")
    send_file file_path, type: 'application/pdf', x_sendfile: true
  end

  private

  def save_url_list
    if @url_list.save
      flash.now[:notice] = 'Client was successfully list.'
      sidq_status = PdfWorker.perform_async(@url_list.urls)
      save_sidq_status(sidq_status)
    else
      flash.now[:error] = 'Error occurred while List.'
    end
  end

  def urls_params
    params.require(:url_list).permit(:user_id, :urls)
  end

  def convert_urls(object)
    object[:urls] = object[:urls].gsub(/\n/, ' ').split(' ')
  end

  def save_sidq_status(sidq_status)
    job = SidekiqStatus.new(job_id: sidq_status, url_list_id: @url_list.id)
    job.save
  end

  def parse_urls
    respond = []
    uris.each_with_index do |uri, index|
      create_pdf(uri)
      respond << { " #{index + 1} ": create_raptor_json(uri[1]) }
    end
    respond.sort_by { |e| e.first.last.first[:info][:Title] }
  end

  def create_pdf(uri)
    uri[1].each do |url|
      raptor_api(url, remove_sum(url))
    rescue StandardError
      next
    end
  end

  def uris
    uris = URI.parse(request.original_fullpath)
    CGI.parse(uris.query)
  end

  def create_raptor_json(urls)
    result = []
    begin
      read_pdf(urls, result)
    rescue StandardError
      result
    end
    result.sort_by { |e| -e[:page_count] }
  end

  def read_pdf(urls, result)
    urls.each do |url|
      reader = PDF::Reader.new(Rails.root.join('tmp', 'pdfs', "#{remove_sum(url)}.pdf"))
      result << { url: reader.pdf_version, pdf_version: reader.pdf_version,
                  info: reader.info, "metadata": reader.metadata,
                  "page_count": reader.page_count }
    end
    result
  end

  def remove_sum(obj)
    obj.gsub(/\W/, '')
  end

  def show_js
    @sidekiq_status = SidekiqStatus.find_by(job_id: params[:process_id])
    errors = @sidekiq_status.sidekiq_errors
    if errors.present?
      flash.now[:error] = "Unfortunately, we can't download PDF(s)
                          from this website(s): #{error_message(errors)}"
    else
      flash.now[:notice] = 'We success download your websites'
    end
  end

  def error_message(errors)
    errors.pluck(:error_messages).join(', ').to_s
  end
end
