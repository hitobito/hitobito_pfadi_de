$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your wagon's version:
require "hitobito_pfadi_de/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "hitobito_pfadi_de"
  s.version = HitobitoPfadiDe::VERSION
  s.authors = ["Carlo Beltrame"]
  s.email = ["beltrame@puzzle.ch"]
  s.summary = "Hitobito-Wagon für Features der BdP und DPSG"
  s.description = "Hitobito-Wagon für Features der BdP und DPSG"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile"]
end
