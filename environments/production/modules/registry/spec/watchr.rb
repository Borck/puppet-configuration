ENV['AUTOTEST'] = 'true'
ENV['WATCHR']   = '1'

system 'clear'

def growl(message)
  growlnotify = `which growlnotify`.chomp
  title = 'Watchr Test Results'
  image = case message
          when %r{(\d+)\s+?(failure|error)}i
            (Regexp.last_match(1).to_i == 0) ? '~/.watchr_images/passed.png' : '~/.watchr_images/failed.png'
          else
            '~/.watchr_images/unknown.png'
          end
  options = "-w -n Watchr --image '#{File.expand_path(image)}' -m '#{message}' '#{title}'"
  system %(#{growlnotify} #{options} &)
end

def run(cmd)
  puts(cmd)
  `#{cmd}`
end

def run_spec_test(file)
  if File.exist? file
    result = run "rspec --format d --color #{file}"
    growl result.split("\n").last
    puts result
  else
    puts "FIXME: No test #{file} [#{Time.now}]"
  end
end

def filter_rspec(data)
  data.split("\n").select { |l|
    l =~ %r{^(\d+)\s+exampl\w+.*?(\d+).*?failur\w+.*?(\d+).*?pending}
  }.join("\n")
end

def run_all_tests
  system('clear')
  files = Dir.glob('spec/**/*_spec.rb').join(' ')
  result = run "rspec --format d --color #{files}"
  growl_results = filter_rspec result
  growl growl_results
  puts result
  puts "GROWL: #{growl_results}"
end

# Ctrl-\
Signal.trap 'QUIT' do
  puts " --- Running all tests ---\n\n"
  run_all_tests
end

@interrupted = false

# Ctrl-C
Signal.trap 'INT' do
  if @interrupted
    @wants_to_quit = true
    abort("\n")
  else
    puts 'Interrupt a second time to quit'
    @interrupted = true
    Kernel.sleep 1.5
    # raise Interrupt, nil # let the run loop catch it
    run_suite
  end
end

def file2spec(file)
  _result = file.sub('lib/puppet/', 'spec/unit/puppet/').gsub(%r{\.rb$}, '_spec.rb')
  _result = file.sub('lib/facter/', 'spec/unit/facter/').gsub(%r{\.rb$}, '_spec.rb')
end

watch('spec/.*_spec\.rb') do |_md|
  # run_spec_test(md[0])
  run_all_tests
end
watch('lib/.*\.rb') do |_md|
  # run_spec_test(file2spec(md[0]))
  run_all_tests
end
