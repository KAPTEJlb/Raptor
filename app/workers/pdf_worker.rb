class PdfWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include Firebase
  include RaptorParser

  def expiration
    @expiration ||= 60 * 60 * 24 * 30 # 30 days
  end

  def perform(urls)
    sleep(2)
    initialize_firebase
    total 100
    job = SidekiqStatus.find_by(job_id: self.jid)
    if urls.count > 0
      procentege = 100 / urls.count
      urls.each_with_index do |url, index|
        begin
          raptor_api(url, url.gsub(/\W/, ''))
          status = job_status(index, urls, procentege)
          at status[0], status[1]
          firebase(self.jid, status[0].to_i, status[1])
          job.update(progress: status[0].to_i, message: status[1])
        rescue

          job.sidekiq_errors.new(error_messages: "#{url}").save
          if urls.size - 1
            status = job_status(index, urls, procentege)
            firebase(self.jid, status[0].to_i, status[1])
          end
          next
        end
      end
    end
  end

  def job_status(index, urls, procentege)
    if index == urls.size - 1
      return  [100, "Done"]
    else
      return [(index + 1) * procentege, "Almost done"]
    end
  end

  def firebase(prs_id, status, message)
    @firebase.update("SidekiqJob/#{prs_id}/", { process_id: prs_id, status: status, message: message })
  end

  def initialize_firebase
    base_uri = 'https://raptor-fc7b8.firebaseio.com'

    @firebase = Firebase::Client.new(base_uri)
  end
end