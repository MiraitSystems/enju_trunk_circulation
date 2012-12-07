$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "enju_trunk_circulation/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "enju_trunk_circulation"
  s.version     = 1.0
  s.authors     = ["Emiko TAMIYA"]
  s.email       = ["tamiya.emiko@miraitsystems.jp"]
  s.homepage    = "https://github.com/nakamura-akifumi/enju_trunk"
  s.summary     = "EnjuCirculation for EnjuTrunk"
  s.description = "to do Checkout, Checkin, Reserve"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.8"
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "sqlite3"
end
