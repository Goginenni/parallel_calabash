module ParallelAppium
  class Runner
    class << self
      @@appium_ports = []

      def base_command
        'cucumber'
      end

      def start_appium(process_number,device_id,appium_cmd)

        chrome_driver_port =  9515 + process_number + 1
        bootstrap_port = 4800 + process_number + 1
        appium_port = 4723 + process_number + 1
        cmd = appium_cmd || 'appium'

        start_appium = "#{cmd} --port #{appium_port} --udid #{device_id} --bootstrap-port #{bootstrap_port} --chromedriver-port #{chrome_driver_port} --log-level error --log appium_#{process_number}.log &"

        system(start_appium)

        appium_started = false

        60.times do
          response = `curl --max-time 2 http://localhost:#{appium_port}/wd/hub/status/`
          appium_started = !response.empty? and JSON.parse(response)['status'].eql?0
          break if appium_started
          sleep(0.5)
        end

        raise 'Can not start Appium' unless appium_started
        @@appium_ports.push(appium_port)
        appium_port
      end

      def stop_all_appium
        no_appium_server = @@appium_ports.size == 0
        3.times do
          `killall node`
          @@appium_ports.each do |appium_port|
            response = `curl --max-time 2 http://localhost:#{appium_port}/wd/hub/status/`
            no_appium_server = response.empty?
          end
          break if no_appium_server
        end
        raise 'Can not stop all appium servers' unless no_appium_server
      end

      def run_tests(test_files, process_number, options)
        cmd = [base_command, options[:cucumber_options], options[:cucumber_reports], *test_files].compact*' '
        execute_command_for_process(process_number, cmd, options[:appium_cmd], options[:mute_output])
      end

      def execute_command_for_process(process_number, cmd, appium_cmd, silence)

        device_id, device_info = ParallelAppium::AdbHelper.device_for_process process_number

        appium_port = start_appium(process_number,device_id,appium_cmd)

        command_for_current_process = command_for_process(process_number, cmd,device_id,device_info,appium_port)
        output = open("|#{command_for_current_process}", "r") { |output| show_output(output, silence) }
        exitstatus = $?.exitstatus

        if silence
          $stdout.print output
          $stdout.flush
        end
        puts "\n****** PROCESS #{process_number} COMPLETED ******\n\n"
        {:stdout => output, :exit_status => exitstatus}

      end

      def command_for_process(process_number,cmd,device_id,device_info,appium_port)
        env = {}

        env = env.merge({AUTOTEST:'1', ADB_DEVICE_ARG:device_id, APPIUM_PORT:appium_port, DEVICE_INFO:device_info, TEST_PROCESS_NUMBER:(process_number+1).to_s, SCREENSHOT_PATH:device_id.to_s + '_'})
        separator = (WINDOWS ? ' & ' : ';')
        exports = env.map { |k, v| WINDOWS ? "(SET \"#{k}=#{v}\")" : "#{k}=#{v};export #{k}" }.join(separator)
        exports + separator + cmd
      end

      def show_output(output, silence)
        result = ""
        loop do
          begin
            read = output.readpartial(1000000) # read whatever chunk we can get
            result << read
            unless silence
              $stdout.print read
              $stdout.flush
            end
          end
        end rescue EOFError
        result
      end

    end
  end
end