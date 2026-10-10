module Slop
  class Parser

    # Our Options instance.
    attr_reader :options

    # A Hash of configuration options.
    attr_reader :config

    # Returns an Array of String arguments that were not parsed.
    attr_reader :arguments

    def initialize(options, **config)
      @options = options
      @config  = config
      reset
    end

    # Reset the parser, useful to use the same instance to parse a second
    # time without duplicating state.
    def reset
      @arguments = []
      @options.each(&:reset)
      self
    end

    # Traverse `strings` and process options one by one. Anything after
    # `--` is ignored. If a flag includes a equals (=) it will be split
    # so that `flag, argument = s.split('=')`.
    #
    # The `call` method will be executed immediately for each option found.
    # Once all options have been executed, any found options will have
    # the `finish` method called on them.
    #
    # Returns a Slop::Result.
    def parse(strings)
      reset # reset before every parse

      # ignore everything after "--"
      strings, ignored_args = partition(strings)

      @arguments = strings.dup
      consumed = Array.new(strings.length, false)
      skip_next = false

      strings.each_with_index do |flag, idx|
        if skip_next
          skip_next = false
          next
        end
        break if !flag
        arg = strings[idx + 1]

        # support `foo=bar`
        orig_flag = flag.dup
        if match = flag.match(/([^=]+)=(.*)/)
          flag, arg = match.captures
        end

        if opt = try_process(flag, arg)
          # Track positions so repeated options do not rescan or shift
          # the remaining arguments on every iteration.
          consumed[idx] = true
          if opt.expects_argument? && !orig_flag.include?("=")
            consumed[idx + 1] = true if idx + 1 < strings.length
            skip_next = consume_next_argument?(orig_flag)
          end
        end
      end

      @arguments = []
      strings.each_with_index do |argument, idx|
        @arguments << argument unless consumed[idx]
      end
      @arguments.concat(ignored_args)

      if !suppress_errors?
        unused_options.each do |o|
          if o.config[:required]
            pretty_flags = o.flags.map { |f| "`#{f}'" }.join(", ")
            raise MissingRequiredOption, "missing required option #{pretty_flags}"
          end
        end
      end

      Result.new(self).tap do |result|
        used_options.each { |o| o.finish(result) }
      end
    end

    # Returns an Array of Option instances that were used.
    def used_options
      options.select { |o| o.count > 0 }
    end

    # Returns an Array of Option instances that were not used.
    def unused_options
      options.to_a - used_options
    end

    private

    def consume_next_argument?(flag)
      return false if flag.include?("=")
      return true if flag.start_with?("--")
      return true if /\A-[a-zA-Z]\z/ === flag
      false
    end

    # We've found an option, process and return it
    def process(option, arg)
      option.ensure_call(arg)
      option
    end

    # Try and find an option to process
    def try_process(flag, arg)
      if option = matching_option(flag)
        process(option, arg)
      elsif flag.start_with?("--no-") && option = matching_option(flag.sub("no-", ""))
        process(option, false)
      elsif flag =~ /\A-[^-]{2,}/
        try_process_smashed_arg(flag) || try_process_grouped_flags(flag, arg)
      else
        if flag.start_with?("-") && !suppress_errors?
          raise UnknownOption.new("unknown option `#{flag}'", "#{flag}")
        end
      end
    end

    # try and process a flag with a "smashed" argument, e.g.
    # -nFoo or -i5
    def try_process_smashed_arg(flag)
      option = matching_option(flag[0, 2])
      if option && option.expects_argument?
        process(option, flag[2..-1])
      end
    end

    # try and process as a set of grouped short flags. drop(1) removes
    # the prefixed -, then we add them back to each flag separately.
    def try_process_grouped_flags(flag, arg)
      flags = flag.split("").drop(1).map { |f| "-#{f}" }
      last  = flags.pop

      flags.each { |f| try_process(f, nil) }
      try_process(last, arg) # send the argument to the last flag
    end

    def suppress_errors?
      config[:suppress_errors]
    end

    def matching_option(flag)
      options.find { |o| o.flags.include?(flag) }
    end

    def partition(strings)
      if strings.include?("--")
        partition_idx = strings.index("--")
        return [[], strings[1..-1]] if partition_idx.zero?
        [strings[0..partition_idx-1], strings[partition_idx+1..-1]]
      else
        [strings, []]
      end
    end
  end
end
