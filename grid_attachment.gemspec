Gem::Specification.new do |s|
  s.name = "grid_attachment"
  s.version = "0.0.1"
  s.author = "Dusty Doris"
  s.email = "github@dusty.name"
  s.homepage = "http://github.com/dusty/grid_attachment"
  s.platform = Gem::Platform::RUBY
  s.summary = "Plugin for various Mongo ODMs to attach files via GridFS"
  s.description = "Plugin for various Mongo ODMs to attach files via GridFS"
  s.files = [
    "README.txt",
    "lib/grid_attachment/mongo_mapper.rb",
    "lib/grid_attachment/mongo_odm.rb",
    "test/test_mongo_mapper.rb",
    "test/test_mongo_odm.rb"
  ]
  s.extra_rdoc_files = ["README.txt"]
  s.add_dependency('mime-types')
  s.rubyforge_project = "none"
end
