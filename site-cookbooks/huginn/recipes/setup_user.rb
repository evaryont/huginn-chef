include_recipe 'sudo'

group node['huginn']['deploy_user']['group'] do
  append true
end

user node['huginn']['deploy_user']['name'] do
  gid node['huginn']['deploy_user']['group']
  home node['huginn']['deploy_user']['home']
  shell node['huginn']['deploy_user']['shell']
  password "$6$ZwO6b.6tij$SMa8UIwtESGDxB37NwHsct.gJfXWmmflNbH.oypwJ9y0KkzMkCdw7D14iK7GX9C4CWSEcpGOFUow7p01rQFu5."
  comment "Huginn Deploy User"
  supports :manage_home => true
end

group node['huginn']['deploy_user']['group'] do
  members node['huginn']['deploy_user']['name']
end

sudo node['huginn']['deploy_user']['name'] do
  group node['huginn']['deploy_user']['group']
  nopasswd true
  commands [
    '/sbin/start huginn',
    '/sbin/stop huginn',
    '/sbin/restart huginn',
    '/sbin/status huginn'
  ]
end
