class PdfWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include Firebase
  include RaptorParser

  def expiration
    @expiration ||= 60 * 60 * 24 * 30 # 30 days
  end

  def perform(urls)
    sleep(1)
    initialize_firebase
    total 100
    if urls.count.positive?
      percentage = 100 / urls.count
      parse_raptor_api(urls, percentage)
    end
  end

  def parse_raptor_api(urls, percentage)
    urls.each_with_index do |url, index|
      raptor_response(urls, url, index, percentage)
    rescue
      wrong_response(urls, url, index, percentage)
      next
    end
  end

  def raptor_response(urls, url, index, percentage)
    raptor_api(url, url.gsub(/\W/, ''))
    status = job_status(index, urls, percentage)
    at status[0], status[1]
    firebase(jid, status[0].to_i, status[1])
    job.update(progress: status[0].to_i, message: status[1])
  end

  def wrong_response(urls, url, index, percentage)
    job.sidekiq_errors.new(error_messages: url.to_s).save
    if urls.size - 1
      status = job_status(index, urls, percentage)
      firebase(jid, status[0].to_i, status[1])
    end
  end

  def job_status(index, urls, percentage)
    if index == (urls.size - 1)
      [100, 'Done']
    else
      [(index + 1) * percentage, 'Almost done']
    end
  end

  def firebase(prs_id, status, message)
    @firebase.update("SidekiqJob/#{prs_id}/", { process_id: prs_id, status: status, message: message })
  end

  def initialize_firebase
    base_uri = 'https://raptor-fc7b8.firebaseio.com'

    @firebase = Firebase::Client.new(base_uri)
  end

  def job
    SidekiqStatus.find_by(job_id: jid)
  end
end