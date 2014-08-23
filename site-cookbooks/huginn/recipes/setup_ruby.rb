include_recipe "rbenv::default"
include_recipe "rbenv::ruby_build"
include_recipe "rbenv::rbenv_vars"

rbenv_ruby node['huginn']['ruby_version']

rbenv_gem "bundler" do
  ruby_version node['huginn']['ruby_version']
end

if platform_family?("rhel")
  packages = node['huginn']['packages']['rhel']
else
  packages = node['huginn']['packages']['default']
end

packages.each do |pkg|
  package pkg
end
