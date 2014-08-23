deploy node['huginn']['deploy_user']['home'] do
  repo node['huginn']['repository']
  revision node['huginn']['revision']
  keep_releases node['huginn']['keep_releases']
  rollback_on_error true

  user node['huginn']['deploy_user']['name']
  group node['huginn']['deploy_user']['group']

  environment "RAILS_ENV" => node['huginn']['rails_env']

  migration_command "bundle exec rake db:migrate --trace"
  migrate false

  # enable_submodules true
  # migrate true
  # migration_command "rake db:migrate"
  # environment "RAILS_ENV" => "production", "OTHER_ENV" => "foo"
  # shallow_clone true

  action :deploy # or :rollback
  # restart_command "touch tmp/restart.txt"
  # git_ssh_wrapper "wrap-ssh4git.sh"
  # scm_provider Chef::Provider::Git # is the default, for svn: Chef::Provider::Subversion

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

  symlinks({
    "log" => "log",
    #{}"config/Procfile" => "Procfile",
    #{}"config/.env" => ".env",
    "config/unicorn.rb" => "/config/unicorn.rb"
  })
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
