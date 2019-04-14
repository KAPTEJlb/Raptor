class HomesController < ApplicationController

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

end
