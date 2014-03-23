require "fileutils"
require "packer_archlinux"

RSpec.configure do |config|
  config.before :each do
    @pwd, @tmp = Dir.pwd, File.expand_path("../tmp", __FILE__)
    FileUtils.mkdir @tmp and Dir.chdir @tmp
  end

  config.after :each do
    Dir.chdir @pwd and FileUtils.rm_rf @tmp
  end

  def capture
    begin
      $stdout, $stderr = StringIO.new, StringIO.new
      yield
      [$stdout.string, $stderr.string]
    rescue
      [$stdout.string, $stderr.string]
    end
  end

  def template(filename)
    JSON.parse filename
  end

  def run(*args)
    @stdout, @stderr = capture { PackerArchLinux.start args }
    @directory = Dir[@tmp + "/**/*.json"]
    @template  = @directory.empty? ? nil : JSON.parse(File.read(@directory.first))
  end

  def file_name
    File.basename @directory.first
  end
end
