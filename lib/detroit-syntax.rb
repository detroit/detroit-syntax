require 'detroit/tool'

module Detroit

  # Create a new Syntax tool with the specified +options+.
  def Syntax(options={})
    Syntax.new(options)
  end

  # The Syntax tool simply checks all Ruby code for syntax errors.
  # It is a rather trivial tool, and is here mainly for example sake.
  #
  # NOTE: This method shells out to the command line using `ruby -c`.
  class Syntax < Tool

    # Files to check.
    attr_accessor :files
   
    # Add these folders to the $LOAD_PATH.
    attr_accessor :loadpath

    # Globs to exclude.
    attr_accessor :exclude

    # Files to ignore based on file name patterns.
    attr_accessor :ignore

    # Extra options to append to `ruby -c` command.
    attr_accessor :extra

    # File name of log file or +true+ to use default `log/syntax.rdoc` file.
    def log=(file_or_bool)
      @log = file_or_bool
    end

    # Log syntax errors?
    def log
      @log
    end


    #  A S S E M B L Y  S T A T I O N S

    # Attach check method to test station.
    def station_test
      check
    end


    #  S E R V I C E  M E T H O D S

    # If log is given save results to this log file.
    def logfile
      case log
      when String
        Pathname.new(log)
      else
        project.log + 'syntax.rdoc'
      end
    end

    # Verify syntax of ruby scripts.
    def check
      list = run_syntax_check

      if log && (logfile.outofdate?(*files) or force?)
        log_syntax_errors(list)
      end

      abort "Syntax errors found." if list.size > 0

      return true
    end

  private

    #
    def run_syntax_check
      files = gather_files
      files = files.select{ |f| File.extname(f) == '.rb' }

      max   = files.collect{ |f| f.size }.max
      list  = []

      puts "Started"

      start = Time.now

      files.each do |file|
        pass = syntax_check_file(file, max)
        list << file if !pass
      end

      puts "\nFinished in %.6f seconds." % [Time.now - start]
      puts "\n#{list.size} Syntax Errors"

      return list
    end

    # Collect files to be checked.
    def gather_files
      amass(files.to_list, exclude.to_list, ignore.to_list)
    end

    # Check a file.
    def syntax_check_file(file, max=nil)
      return unless File.file?(file)
      max  = max || file.size + 2
      #libs = loadpath.join(';')
      #r = system "ruby -c -Ibin:lib:test #{s} &> /dev/null"
      r = system "ruby -c #{opt_I} #{extra} #{file} > /dev/null 2>&1"
      if r
        if verbose?
          printline("%-#{max}s" % file, "[PASS]")
        else
          print '.'
        end
        true
      else
        if verbose?
          printline("%-#{max}s" % file, "[FAIL]")
          #puts("%-#{max}s  [FAIL]" % [s])
        else
          print 'E'
        end
        false
      end
    end

    # Create syntax log.
    def log_syntax_errors(list)
      #logfile = project.log + 'syntax.log'
      mkdir_p(logfile.parent)
      begin
        file = File.open(logfile, 'w+')
        file << "= SYNTAX ERROR LOG\n"
        file << "\n(#{Time.now})\n\n"
        if list.empty?
          file << "No Syntax Errors."
        else
          list.each do |file|
            err = `ruby -c #{opt_I} #{extra} #{file} 2>&1`
            file << "== #{file}\n#{err}\n\n"
          end
        end
        file << "\n\n"
      ensure
        file.close
      end

    end

    #
    def opt_I
      loadpath.map{ |r| "-I#{r}" }.join(' ')
    end

    #
    def initialize_defaults
      @loadpath = metadata.loadpath
      @exclude  = []
    end

  public

    def self.man_page
      File.dirname(__FILE__)+'/../man/detroit-syntax.5'
    end

  end

end

=begin
    # Load each script independently to ensure there are no
    # require dependency issues.
    #
    # WARNING! You should only run this on scripts that have no
    # toplevel side-effects!!!
    #
    # This takes one option +:libpath+ which is a glob or list of globs
    # of the scripts to check. By default this is all scripts in the libpath(s).
    #
    # FIXME: This isn't routing output to dev/null as expected ?

    def check_load(options={})
      #options = configure_options(options, 'check-load', 'check')

      make if compiles?

      libpath = options['libpath'] || loadpath()
      exclude = options['exclude'] || exclude()

      libpath = libpath.to_list
      exclude = exclude.to_list

      files = multiglob_r(*libpath) - multiglob_r(*exclude)
      files   = files.select{ |f| File.extname(f) == '.rb' }
      max   = files.collect{ |f| f.size }.max
      list  = []

      files.each do |s|
        next unless File.file?(s)
        #if not system "ruby -c -Ibin:lib:test #{s} &> /dev/null" then
        cmd = "ruby -I#{libpath.join(':')} #{s} > /dev/null 2>&1"
        puts cmd if debug?
        if r = system(cmd)
          puts "%-#{max}s  [PASS]" % [s]
        else
          puts "%-#{max}s  [FAIL]" % [s]
          list << s #:load
        end
      end

      puts "  #{list.size} Load Failures"

      if verbose?
        unless list.empty?
          puts "\n-- Load Failures --\n"
          list.each do |f|
            print "* "
            system "ruby -I#{libpath} #{f} 2>&1"
            #puts
          end
          puts
        end
      end
    end

=end

