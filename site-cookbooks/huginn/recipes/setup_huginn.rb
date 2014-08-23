#deploy node['huginn']['deploy_user']['home'] do
application "huginn" do
  path node['huginn']['deploy_user']['home']

  repository node['huginn']['repository']
  revision node['huginn']['revision']
  #keep_releases node['huginn']['keep_releases']
  rollback_on_error true

  #user node['huginn']['deploy_user']['name']
  owner node['huginn']['deploy_user']['name']
  group node['huginn']['deploy_user']['group']

  environment "RAILS_ENV" => node['huginn']['rails_env']

  #restart_command ""

  # enable_submodules true
  # migrate true
  # migration_command "rake db:migrate"
  # environment "RAILS_ENV" => "production", "OTHER_ENV" => "foo"
  # shallow_clone true

  action :force_deploy #:deploy # or :rollback
  # restart_command "touch tmp/restart.txt"
  # git_ssh_wrapper "wrap-ssh4git.sh"
  # scm_provider Chef::Provider::Git # is the default, for svn: Chef::Provider::Subversion

  before_migrate do
    file "#{node['huginn']['deploy_user']['home']}/shared/.ruby-version" do
      owner node['huginn']['deploy_user']['name']
      group node['huginn']['deploy_user']['group']
      action :create
      content node['huginn']['ruby_version']
    end

    rbenv_execute "create/seed db" do
      ruby_version node['huginn']['ruby_version']
      cwd "#{node['huginn']['deploy_user']['home']}/current"
      command <<-EOH
        bundler exec rake db:create && bundler exec rake db:migrate && bundler exec rake db:seed && echo 1 > #{node['huginn']['deploy_user']['home']}/shared/RAKE-DB-CREATED
      EOH
    end

  end

  symlink_before_migrate({
    ".ruby-version" => ".ruby-version",
    "config/database.yml" => "config/database.yml"
  })

  migrate true
  # migration_command "bundle exec rake db:migrate --trace"

  before_symlink do
    %w(config log tmp tmp/pids tmp/sockets).each do |dir|
      directory "#{node['huginn']['deploy_user']['home']}/shared/#{dir}" do
        owner node['huginn']['deploy_user']['name']
        group node['huginn']['deploy_user']['group']
        recursive true
      end
    end

    # Procfile
    %w(unicorn.rb nginx.conf).each do |file|
      cookbook_file "#{node['huginn']['deploy_user']['home']}/shared/config/#{file}" do
        owner node['huginn']['deploy_user']['name']
        group node['huginn']['deploy_user']['group']
        action :create
      end
    end

  end

  before_restart do
    rbenv_execute "export huginn service" do
      ruby_version node['huginn']['ruby_version']
      cwd "#{node['huginn']['deploy_user']['home']}/current"
      command "bundler exec foreman export upstart /etc/init -a huginn -u #{node['huginn']['deploy_user']['name']} -l log"
    end

    service "huginn" do
      provider Chef::Provider::Service::Upstart
      supports :restart => true, :start => true, :stop => true#, :reload => true
      action :enable
    end

  end

  symlinks({
    "log" => "log",
    #{}"config/Procfile" => "Procfile",
    #{}"config/.env" => ".env",
    "config/unicorn.rb" => "config/unicorn.rb"
  })

  rails do
    bundler true
    bundle_command "rbenv exec bundle"
  end

end

# application "huginn" do
#   path "#{node['huginn']['deploy_user']['home']}/huginn"
#   repository node['huginn']['repository']
#   checkout_branch node['huginn']['branch']
#   #revision node['huginn']['branch']

#   keep_releases node['huginn']['keep_releases']
#   rollback_on_error true

#   owner node['huginn']['deploy_user']['name']
#   group node['huginn']['deploy_user']['group']

#   rails do

#   end

#   unicorn do
#     bundler true
#     preload_app true
#     worker_processes 2
#     working_directory "#{node['huginn']['deploy_user']['home']}/huginn/current"
#   end

#   nginx_load_balancer do
#     init_style "upstart"
#     #only_if { node['roles'].include?('my-app_load_balancer') }
#     set_host_header true
#   end
# end
