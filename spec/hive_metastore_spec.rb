require 'spec_helper'

describe 'hadoop::hive_metastore' do
  context 'on Centos 6.5 x86_64' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: 6.5) do |node|
        node.automatic['domain'] = 'example.com'
        stub_command('update-alternatives --display hive-conf | grep best | awk \'{print $5}\' | grep /etc/hive/conf.chef').and_return(false)
        stub_command(%r{/sys/kernel/mm/(.*)transparent_hugepage/defrag}).and_return(false)
      end.converge(described_recipe)
    end
    pkg = 'hive-metastore'

    it "does not install #{pkg} package" do
      expect(chef_run).not_to install_package(pkg)
    end

    it "runs package-#{pkg} ruby_block" do
      expect(chef_run).to run_ruby_block("package-#{pkg}")
    end

    it "creates #{pkg} service resource, but does not run it" do
      expect(chef_run).to_not disable_service(pkg)
      expect(chef_run).to_not enable_service(pkg)
      expect(chef_run).to_not reload_service(pkg)
      expect(chef_run).to_not restart_service(pkg)
      expect(chef_run).to_not start_service(pkg)
      expect(chef_run).to_not stop_service(pkg)
    end

    it "creates /etc/init.d/#{pkg} from template" do
      expect(chef_run).to create_template('/etc/init.d/hive-metastore')
    end

    it 'does not run execute[hive-hdfs-warehousedir]' do
      expect(chef_run).not_to run_execute('hive-hdfs-warehousedir')
    end
  end
end
