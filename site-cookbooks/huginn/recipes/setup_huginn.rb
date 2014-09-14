node_database_password = node['huginn']['database_password'] # Set this here since it doesn't seem to like using the hash directly later

#deploy node['huginn']['deploy_user']['home'] do
application "huginn" do
  path node['huginn']['deploy_user']['home']

  repository node['huginn']['repository']
  revision node['huginn']['revision']
  #keep_releases node['huginn']['keep_releases']
  rollback_on_error false # true TODO CHANGEME

  #user node['huginn']['deploy_user']['name']
  owner node['huginn']['deploy_user']['name']
  group node['huginn']['deploy_user']['group']

  environment "RAILS_ENV" => node['huginn']['rails_env'], "RBENV_VERSION" => node['huginn']['ruby_version']

  migrate true
  # migration_command "bundle exec rake db:migrate --trace"

  #restart_command ""

  # enable_submodules true
  # migrate true
  # migration_command "rake db:migrate"
  # environment "RAILS_ENV" => "production", "OTHER_ENV" => "foo"
  # shallow_clone true

  action :deploy #:force_deploy # or :rollback
  # restart_command "touch tmp/restart.txt"
  # git_ssh_wrapper "wrap-ssh4git.sh"
  # scm_provider Chef::Provider::Git # is the default, for svn: Chef::Provider::Subversion

  # before_migrate do

  #   # rbenv_execute "create/seed db" do
  #   #   ruby_version node['huginn']['ruby_version']
  #   #   cwd "#{node['huginn']['deploy_user']['home']}/current"
  #   #   command <<-EOH
  #   #     bundler exec rake db:create && bundler exec rake db:migrate && bundler exec rake db:seed && echo 1 > #{node['huginn']['deploy_user']['home']}/shared/RAKE-DB-CREATED
  #   #   EOH
  #   # end

  # end

  before_migrate do
    # From https://github.com/poise/application_ruby/blob/master/providers/rails.rb
    Chef::Log.info "Running bundle install"
    directory "#{new_resource.path}/shared/vendor_bundle" do
      owner new_resource.owner
      group new_resource.group
      mode '0755'
    end
    directory "#{new_resource.release_path}/vendor" do
      owner new_resource.owner
      group new_resource.group
      mode '0755'
    end
    link "#{new_resource.release_path}/vendor/bundle" do
      to "#{new_resource.path}/shared/vendor_bundle"
    end

    common_groups = %w{development test cucumber staging}
    bundle_command = "bundle install --path=vendor/bundle --without #{common_groups}"

    rbenv_execute "bundle-install" do
      cwd new_resource.release_path
      user new_resource.owner

      ruby_version node['huginn']['ruby_version']

      command bundle_command
    end

    # rbenv_execute "bundle-install" do
    #   user node['huginn']['deploy_user']['name']
    #   cwd release_path

    #   ruby_version node['huginn']['ruby_version']
    #   creates "#{node['huginn']['deploy_user']['home']}/shared/rakesecret"

    #   command <<-EOH
    #   bundle install --without development test cucumber staging mysql
    #   EOH
    # end

    # bash "link-vendor-bundle" do
    #   user node['huginn']['deploy_user']['name']
    #   cwd "#{release_path}/vendor"

    #   only_if

    #   code <<-EOH
    #   rm -f bundle
    #   ln -s #{node['huginn']['deploy_user']['home']}/shared/vendor_bundle bundle
    #   EOH
    # end

    Chef::Log.info "Creating rake secret (if required)"
    rbenv_execute "create-rake-secret" do
      user node['huginn']['deploy_user']['name']
      cwd release_path

      ruby_version node['huginn']['ruby_version']
      creates "#{node['huginn']['deploy_user']['home']}/shared/rakesecret"

      command <<-EOH
      bundle exec rake secret > #{node['huginn']['deploy_user']['home']}/shared/rakesecret
      EOH
    end

    Chef::Log.info "Removing old dotenv config file"
    bash "remove-old-dotenv" do
      user node['huginn']['deploy_user']['name']
      cwd "#{node['huginn']['deploy_user']['home']}/shared"

      code <<-EOH
      rm -f dotenv
      EOH
    end

    Chef::Log.info "Copying .env.example to dotenv"
    bash "copy-example-dotenv" do
      user node['huginn']['deploy_user']['name']
      cwd release_path

      code <<-EOH
      cp .env.example #{node['huginn']['deploy_user']['home']}/shared/dotenv
      EOH
    end

    Chef::Log.info "Configuring new dotenv config file"
    bash "configure-dotenv" do
      user node['huginn']['deploy_user']['name']
      cwd "#{node['huginn']['deploy_user']['home']}/shared"

      code <<-'EOH'
      #sed -i 's/^\(APP_SECRET_TOKEN\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(SMTP_DOMAIN\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(SMTP_USER_NAME\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(SMTP_PASSWORD\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(SMTP_SERVER\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(SMTP_PORT\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(SMTP_AUTHENTICATION\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(SMTP_ENABLE_STARTTLS_AUTO\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(EMAIL_FROM_ADDRESS\s*=\s*\).*$/\1TODO/' dotenv
      EOH
    end

    # bash "create-dotenv" do
    #   cwd "#{node['huginn']['deploy_user']['home']}/shared/"
    #   code <<-EOH
    #   rm -f dotenv1 && touch dotenv1
    #   echo test >> dotenv1
    #   echo APP_SECRET_TOKEN=REPLACE_ME_NOW! >> dotenv1
    #   echo DOMAIN=localhost:3000 >> dotenv1
    #   echo RAILS_ENV=production >> dotenv1
    #   echo FORCE_SSL=false >> dotenv1
    #   echo INVITATION_CODE=try-huginn >> dotenv1
    #   echo SMTP_DOMAIN=your-domain-here.com >> dotenv1
    #   echo SMTP_USER_NAME=you@gmail.com >> dotenv1
    #   echo SMTP_PASSWORD=somepassword >> dotenv1
    #   echo SMTP_SERVER=smtp.gmail.com >> dotenv1
    #   echo SMTP_PORT=587 >> dotenv1
    #   echo SMTP_AUTHENTICATION=plain >> dotenv1
    #   echo SMTP_ENABLE_STARTTLS_AUTO=true >> dotenv1
    #   echo EMAIL_FROM_ADDRESS=from_address@gmail.com >> dotenv1
    #   echo AGENT_LOG_LENGTH=200 >> dotenv1
    #   echo TWITTER_OAUTH_KEY= >> dotenv1
    #   echo TWITTER_OAUTH_SECRET= >> dotenv1
    #   echo THIRTY_SEVEN_SIGNALS_OAUTH_KEY= >> dotenv1
    #   echo THIRTY_SEVEN_SIGNALS_OAUTH_SECRET= >> dotenv1
    #   echo GITHUB_OAUTH_KEY= >> dotenv1
    #   echo GITHUB_OAUTH_SECRET= >> dotenv1
    #   echo AWS_ACCESS_KEY_ID="your aws access key id" >> dotenv1
    #   echo AWS_ACCESS_KEY="your aws access key" >> dotenv1
    #   echo AWS_SANDBOX=false >> dotenv1
    #   EOH
    # end

    # bash "before-migrate-inline" do
    #   code <<-EOH
    #   pwd > /home/huginn/inline-curdir.test
    #   EOH
    # end

    # file "/home/huginn/inline-releasepath.test" do
    #   content release_path
    #   action :create
    # end

    # file "/home/huginn/inline-newresource.test" do
    #   content new_resource.to_yaml
    #   action :create
    # end
  end

  symlink_before_migrate({
    #"config/database.yml" => "config/database.yml",
    "dotenv" => ".env"
  })

  # create_dirs_before_symlink

  before_symlink do
    # Replace this with create_dirs_before_symlink?
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
    # "log" => "log",
    #{}"config/Procfile" => "Procfile",
    #{}"config/.env" => ".env",
    "config/unicorn.rb" => "config/unicorn.rb"
  })

  rails do
    bundler true
    # bundle_command "rbenv exec bundle"
    # bundle_command "bundle"

    # precompile_assets true

    symlink_logs true

    # symlink_before_migrate({
    #   # "config/database.yml" => "config/database.yml",
    #   ".ruby-version" => ".ruby-version"
    # })

    database_template "database.yml.erb"

    database do
      password node_database_password
    end

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
