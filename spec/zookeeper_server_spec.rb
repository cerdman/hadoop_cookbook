require 'spec_helper'

describe 'hadoop::zookeeper_server' do
  context 'on Centos 6.5 x86_64' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: 6.5) do |node|
        node.automatic['domain'] = 'example.com'
        node.automatic['hostname'] = 'localhost'
        node.default['zookeeper']['zoocfg']['dataDir'] = '/var/lib/zookeeper'
        node.default['zookeeper']['zoocfg']['server.1'] = 'localhost:2181'
        node.default['zookeeper']['zookeeper_env']['zookeeper_log_dir'] = '/data/log/zookeeper'
        stub_command('test -L /var/log/zookeeper').and_return(false)
        stub_command('update-alternatives --display zookeeper-conf | grep best | awk \'{print $5}\' | grep /etc/zookeeper/conf.chef').and_return(false)
        stub_command('test -e /usr/lib/bigtop-utils/bigtop-detect-javahome').and_return(false)
      end.converge(described_recipe)
    end

    it 'install zookeeper-server package' do
      expect(chef_run).to install_package('zookeeper-server')
    end

    it 'creates zookeeper conf_dir' do
      expect(chef_run).to create_directory('/etc/zookeeper/conf.chef').with(
        user: 'root',
        group: 'root'
      )
    end

    %w(/var/lib/zookeeper/myid /etc/zookeeper/conf.chef/log4j.properties /etc/zookeeper/conf.chef/zoo.cfg).each do |file|
      it "creates #{file} template" do
        expect(chef_run).to create_template(file)
      end
    end

    it 'renders file zoo.cfg with dataDir=/var/lib/zookeeper' do
      expect(chef_run).to render_file('/etc/zookeeper/conf.chef/zoo.cfg').with_content(
        %r{dataDir=/var/lib/zookeeper}
      )
    end

    it 'renders file myid with server.1=localhost:2181' do
      expect(chef_run).to render_file('/etc/zookeeper/conf.chef/zoo.cfg').with_content(
        /server.1=localhost:2181/
      )
    end

    it 'creates zookeeper group' do
      expect(chef_run).to create_group('zookeeper')
    end

    it 'creates zookeeper dataDir' do
      expect(chef_run).to create_directory('/var/lib/zookeeper').with(
        user: 'zookeeper',
        group: 'hadoop'
      )
    end

    it 'creates zookeeper ZOOKEEPER_LOG_DIR' do
      expect(chef_run).to create_directory('/data/log/zookeeper').with(
        mode: '0755',
        user: 'zookeeper',
        group: 'zookeeper'
      )
    end

    it 'deletes /var/log/zookeeper' do
      expect(chef_run).to delete_directory('/var/log/zookeeper')
    end

    it 'creates /var/log/zookeeper symlink' do
      link = chef_run.link('/var/log/zookeeper')
      expect(link).to link_to('/data/log/zookeeper')
    end

    it 'creates /etc/zookeeper/conf.chef/zookeeper-env.sh template' do
      expect(chef_run).to create_template('/etc/zookeeper/conf.chef/zookeeper-env.sh')
    end

    it 'creates /usr/lib/bigtop-utils directory' do
      expect(chef_run).to create_directory('/usr/lib/bigtop-utils')
    end

    it 'creates file /usr/lib/bigtop-utils/bigtop-detect-javahome' do
      expect(chef_run).to touch_file('/usr/lib/bigtop-utils/bigtop-detect-javahome')
    end

    it 'logs hdp-2.1 release engineering fix' do
      expect(chef_run).to write_log('Performing workaround for broken zookeeper-server init script on HDP 2.1')
    end

    it 'creates zookeeper-server service resource, but does not run it' do
      expect(chef_run).to_not start_service('zookeeper-server')
    end

    it 'runs execute[update zookeeper-conf alternatives]' do
      expect(chef_run).to run_execute('update zookeeper-conf alternatives')
    end
  end
end
