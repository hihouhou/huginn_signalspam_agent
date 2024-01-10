module Agents
  class SignalspamAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule 'never'

    description do
      <<-MD
      The Signalspam Agent reports spam to signal-spam.fr.

      `debug` is used for verbose mode.

      `username` is mandatory for authentication.

      `password` is mandatory for authentication.

      `raw_email` is the content of the email in raw.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:

          {
            "report_status": "202"
          }
    MD

    def default_options
      {
        'username' => '',
        'password' => '',
        'raw_email' => '',
        'debug' => 'false',
        'expected_receive_period_in_days' => '2',
      }
    end

    form_configurable :username, type: :string
    form_configurable :password, type: :string
    form_configurable :raw_email, type: :string
    form_configurable :debug, type: :boolean
    form_configurable :expected_receive_period_in_days, type: :string
    def validate_options
      unless options['username'].present?
        errors.add(:base, "username is a required field")
      end

      unless options['password'].present?
        errors.add(:base, "password is a required field")
      end

      unless options['raw_email'].present?
        errors.add(:base, "raw_email is a required field")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          log event
          report
        end
      end
    end

    def check
      report
    end

    private

    def set_credential(name, value)
      c = user.user_credentials.find_or_initialize_by(credential_name: name)
      c.credential_value = value
      c.save!
    end

    def log_curl_output(code,body)

      log "request status : #{code}"

      if interpolated['debug'] == 'true'
        log "request status : #{code}"
        if !body.empty?
          log "body"
          log body
        else
          log "body is empty"
        end
      end

    end

    def report()

      url = URI.parse('https://www.signal-spam.fr/api/signaler')
      headers = {
        'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64; rv:45.0) Gecko/20100101 Thunderbird/52.4.0'
      }
    
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https')
    
      request = Net::HTTP::Post.new(url.path, headers)
      request.basic_auth(interpolated['username'], interpolated['password'])
      request.set_form_data('message' => interpolated['raw_email'])
    
      response = http.request(request)
    
      log_curl_output(response.code,response.body)

      create_event :payload => { 'report_status' => response.code}

    end
  end
end
