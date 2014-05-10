require 'mkmf'
require 'open3'

module ConfigCurator

  # Lookup if a package is installed on the system.
  # See {TOOLS} for supported package tools.
  # If {#tool} is not explicitly set, it will try and choose one automatically.
  # @example Lookup a package
  #   PackageLookup.new.installed? 'ruby' #=> true
  # @example Lookup a package using `pacman`
  #   PackageLookup.new(tool: :pacman).installed? 'ruby' #=> true
  class PackageLookup

    # Error when a package lookup cannot be completed.
    class LookupFailed < RuntimeError; end

    # Default list of supported package tools.
    TOOLS = %i(dpkg pacman)

    attr_accessor :tool, :tools

    def initialize tool: nil
      self.tool = tool
    end

    # Package tools that support package lookup ordered by preference.
    # @return [Array] list of supported package tools
    def tools
      @tools ||= TOOLS
    end

    # The package tool to use for this instance.
    # @return [Symbol] tool to use
    def tool
      return @tool if @tool

      tools.each do |cmd|
        if command? cmd
          return @tool = cmd
        end
      end
      @tool
    end

    # Checks if package is installed.
    # @param package [String] package name to check
    # @return [Boolean] if package is installed
    def installed? package
      fail LookupFailed, 'No supported package tool found.' if tool.nil?
      send tool, package
    end

    private

    # Checks if command exists.
    # @param command [String] command name to check
    # @return [String, nil] full path to command or nil if not found
    def command? command
      MakeMakefile::Logging.instance_variable_set :@logfile, File::NULL
      MakeMakefile::Logging.quiet = true
      MakeMakefile.find_executable command.to_s
    end

    #
    # Tool specific package lookup methods below.
    #

    def dpkg package
      cmd = command? 'dpkg'
      Open3.popen3 cmd, '-s', package do |_, _ , _, wait_thr|
        wait_thr.value.to_i == 0
      end
    end

    def pacman package
      cmd = command? 'pacman'
      Open3.popen3 cmd, '-qQ', package do |_, _ , _, wait_thr|
        wait_thr.value.to_i == 0
      end
    end
  end

end
