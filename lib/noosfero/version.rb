module Noosfero
  PROJECT = 'noosfero'
  VERSION = '1.1~rc1'
end

root = File.expand_path(File.dirname(__FILE__) + '/../..')
if File.exist?(File.join(root, '.git'))
  Noosfero::VERSION.clear << Dir.chdir(root) { `git describe --tags`.strip }
end
