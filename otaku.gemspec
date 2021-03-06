# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{otaku}
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["NgTzeYang"]
  s.date = %q{2010-09-15}
  s.description = %q{}
  s.email = %q{ngty77@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "HISTORY.txt",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/otaku.rb",
     "lib/otaku/client.rb",
     "lib/otaku/encoder.rb",
     "lib/otaku/handler.rb",
     "lib/otaku/server.rb",
     "otaku.gemspec",
     "spec/integration_spec.rb",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/ngty/otaku}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Dead simple service framework built on eventmachine}
  s.test_files = [
    "spec/integration_spec.rb",
     "spec/spec_helper.rb",
     "examples/unittest/client.rb",
     "examples/unittest/tests/b_test.rb",
     "examples/unittest/tests/a_test.rb",
     "examples/unittest/server.rb",
     "examples/unittest/server2.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bacon>, [">= 0"])
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.12.10"])
      s.add_runtime_dependency(%q<serializable_proc>, [">= 0.4.0"])
    else
      s.add_dependency(%q<bacon>, [">= 0"])
      s.add_dependency(%q<eventmachine>, [">= 0.12.10"])
      s.add_dependency(%q<serializable_proc>, [">= 0.4.0"])
    end
  else
    s.add_dependency(%q<bacon>, [">= 0"])
    s.add_dependency(%q<eventmachine>, [">= 0.12.10"])
    s.add_dependency(%q<serializable_proc>, [">= 0.4.0"])
  end
end

