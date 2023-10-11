# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/**/*_test.rb"]
end

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  # Optional dependency
end

require "rb_sys/extensiontask"

task build: :compile

RbSys::ExtensionTask.new("blake3_ext") do |ext|
  ext.lib_dir = "lib/digest/blake3"
end

task default: [:compile, :test, :rubocop]
