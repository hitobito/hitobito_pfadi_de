$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your wagon's version:
require 'hitobito_pfadi_de/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  # rubocop:disable SingleSpaceBeforeFirstArg
  s.name        = 'hitobito_pfadi_de'
  s.version     = HitobitoPfadiDe::VERSION
  s.authors     = ['Carlo Beltrame']
  s.email       = ['beltrame@puzzle.ch']
  s.summary     = 'Hitobito-Wagon für Features der Pfadfinder-Organisationen Deutschland'
  s.description = 'Hitobito-Wagon für Features der Pfadfinder-Organisationen Deutschland'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['Rakefile']
  s.test_files = Dir['test/**/*']
  # rubocop:enable SingleSpaceBeforeFirstArg
end
