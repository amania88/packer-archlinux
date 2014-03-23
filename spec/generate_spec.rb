require "spec_helper"

describe PackerArchLinux do
  describe "generate" do
    context "--force" do
      it do
        run "generate" and run "generate", "--force"
        @directory.size.should == 1
      end

      it do
        run "generate" and run "generate", "-f"
        @directory.size.should == 1
      end

      it do
        run "generate" and run "generate", "--force"
        file_name.should == "packer-archlinux.json"
      end
    end

    context "--name" do
      it do
        run "generate", "--name"
        file_name.should == "packer-archlinux.json"
      end

      it do
        run "generate", "--name", "packer"
        file_name.should == "packer.json"
      end

      it do
        run "generate", "--name", "packer.json"
        file_name.should == "packer.json"
      end
    end

    context "--path" do
      it do
        run "generate", "--path", "."
        @directory.first.should == @tmp + "/packer-archlinux.json"
      end

      it do
        FileUtils.mkdir_p "test" and Dir.chdir "test"
        run "generate", "--path", ".."
        @directory.first.should == @tmp + "/packer-archlinux.json"
      end

      it do
        FileUtils.mkdir_p "test"
        run "generate", "--path", "test"
        @directory.first.should == @tmp + "/test/packer-archlinux.json"
      end

      it do
        run "generate", "--path", "test"
        @stderr.should == "No such directory - #{@tmp}/test\n"
      end
    end

    context "--cookbook" do
      it do
        run "generate", "--cookbook", "./cookbooks"
        @template["provisioners"][0]["cookbook_paths"].should == ["#{@tmp}/cookbooks"]
      end

      it do
        run "generate", "--cookbook", "cookbooks,another/cookbooks"
        @template["provisioners"][0]["cookbook_paths"].should == ["#{@tmp}/cookbooks", "#{@tmp}/another/cookbooks"]
      end

      it do
        run "generate", "--cookbook", "./cookbooks"
        file_name.should == "packer-archlinux.json"
      end
    end

    context "--run-list" do
      it do
        run "generate", "--run-list"
        @template["provisioners"][0]["run_list"].should == ["recipe[default]"]
      end

      it do
        run "generate", "--run-list", "recipe[test]"
        @template["provisioners"][0]["run_list"].should == ["recipe[test]"]
      end

      it do
        run "generate", "--run-list", "recipe[test],recipe[another]"
        @template["provisioners"][0]["run_list"].should == ["recipe[test]", "recipe[another]"]
      end

      it do
        run "generate", "--run-list", "recipe[test]"
        file_name.should == "packer-archlinux.json"
      end
    end

    context "--dry-run" do
      it "outputs valid JSON" do
        run "generate", "--dry-run"
        @stdout.should =~ /^{*}$/
      end

      it do
        run "generate", "--dry-run"
        @directory.should be_empty
      end
    end

    context "extra args" do
      it "returns an error" do
        run "generate", "unknown"
        @stderr.should =~ /^ERROR:/
      end
    end

    context "unknown argument" do
      it "returns an error" do
        run "generate", "--unknown"
        @stderr.should =~ /^ERROR:/
      end
    end
  end
end
