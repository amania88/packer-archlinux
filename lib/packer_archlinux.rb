require "json"
require "thor"

class PackerArchLinux < Thor
  TEMPLATES_DIR = File.expand_path "../../templates", __FILE__
  TEMPLATE_JSON = File.join TEMPLATES_DIR, "template.json"
  COOKBOOKS_DIR = File.join TEMPLATES_DIR, "chef/cookbooks"

  desc "generate", "Generate packer template"
  option :cookbook, :default => COOKBOOKS_DIR
  option :force,    :aliases => :f, :type => :boolean
  option :name,     :default => "packer-archlinux"
  option :user,     :default => "vagrant"
  option :password, :default => "vagrant"
  option :path,     :default => "."
  option :run_list, :default => "recipe[default]"
  option :dry_run,  :type    => :boolean
  def generate
    template = JSON.load File.read TEMPLATE_JSON
    # TODO: this version only
    template["builders"].collect! do |builders|
      builders["iso_url"]           = "http://ftp.jaist.ac.jp/pub/Linux/ArchLinux/iso/2014.03.01/archlinux-2014.03.01-dual.iso"
      builders["iso_checksum"]      = "bc24540b60a5128d51b6abda462807ce51c77704"
      builders["iso_checksum_type"] = "sha1"
      builders["http_directory"]    = TEMPLATES_DIR
      builders["ssh_username"]      = options[:user]
      builders["ssh_password"]      = options[:password]

      if options["password"] != "vagrant"
        builders["shutdown_command"] = "echo '#{options[:password]}' | sudo -S shutdown -P now"
      end

      builders
    end

    cookbook = template["provisioners"].find { |prov| prov["type"] == "chef-solo" }
    cookbook["run_list"]       = options[:run_list].split(",").map(&:strip)
    cookbook["cookbook_paths"] = options[:cookbook].split(",").map do |cookbook|
      File.expand_path cookbook.strip
    end

    template = JSON.pretty_generate template

    if options[:dry_run] then puts template; return end

    target = File.expand_path(options[:path])

    warn "No such directory - #{target}" and return unless Dir.exist? target

    target = File.join(target, options[:name])
    target = target  + ".json" unless /\.json$/ =~ target

    if File.exist?(target) && !options[:force]
      user = ask "Target file already exists. Overwrite? [yes]:", :yellow
      abort unless user == "y" || user == "yes"
    end

    File.open(target, "w") { |f| f.write template }
    say "#{target} was successfully generated!", :green
  end
end
