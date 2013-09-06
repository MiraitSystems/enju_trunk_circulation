$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "enju_trunk_circulation/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "enju_trunk_circulation"
  s.version     = EnjuTrunkCirculation::VERSION
  s.authors     = ["Emiko TAMIYA"]
  s.email       = ["tamiya.emiko@miraitsystems.jp"]
  s.homepage    = "https://github.com/nakamura-akifumi/enju_trunk"
  s.summary     = "EnjuCirculation for EnjuTrunk"
  s.description = "to do Checkout, Checkin, Reserve"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.8"
  s.add_dependency "breadcrumbs_on_rails"
  s.add_dependency "cancan"
  s.add_dependency "attribute_normalizer"
  s.add_dependency 'state_machine'
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "enju_core", "~> 0.1.1.pre2"
  s.add_development_dependency "enju_trunk_frbr"
  s.add_development_dependency "sunspot_solr", "~> 2.0.0.pre.130115"
  s.add_development_dependency 'paper_trail', '~> 2.6'
  s.add_development_dependency 'enju_subject', '0.1.0.pre5'
  s.add_development_dependency 'paperclip', '2.8'
  s.add_development_dependency 'geocoder'
  s.add_development_dependency 'enju_trunk_ill'
end
