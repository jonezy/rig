require 'rake/clean'

SELF_PATH = File.dirname(__FILE__)
PATH_TO_MSBUILD = "C:\\Windows\\Microsoft.NET\\Framework\\v3.5\\msbuild.exe"
TARGET_ENV = "staging"

# list of files and directories to clean, change to suit your liking
CLEAN.exclude("**/core")
CLEAN.include("*.cache", "*.xml", "*.suo", "**/obj", "**/bin", "../Deploy")

$BUILD_FORMAT = "1.0.{s}"
$SVN_REVISION

task :default => :build

# builds all the .sln files in the directory
task :build do 
  desc "builds all of the .sln files in the current directory"
  Dir.glob('*.sln') do |file|
    sh "#{PATH_TO_MSBUILD} /v:q #{SELF_PATH}/#{file}"
  end
end

namespace "deploy" do
  desc "Preps the project for deployment"
  task :project, :project_name, :destination do |t, args|
    begin
      TARGET_ENV = args.destination if args.destination.to_s != ""
        
      config_file = "Web.config.#{TARGET_ENV}"

      Rake::Task["clean"].invoke # clean everything up
      Rake::Task["build"].invoke # build the project

      if !File.exists?('../Deploy') then
        Dir.mkdir("../Deploy") # make sure the deploy directory is present
      end

      get_version(args.project_name)
      version_number = "1.0.#{$SVN_REVISION}"
      package_name = "#{args.project_name}.#{version_number}"

      # copies the main project files
      sh "xcopy .\\#{args.project_name} ..\\Deploy\\#{package_name}\\ /S /C /Y /Q /exclude:e.txt"
      begin
        #copies the projects deployment specific config file
        sh "xcopy .\\#{args.project_name}\\#{config_file} ..\\Deploy\\#{package_name}\\Web.config /S /C /Y /Q" 
      rescue Exception=>e
        puts e
      end
    rescue Exception=>e
      puts e
    end
  end

  def get_version(project_name)
    $SVN_REVISION = %x[svn info -rHEAD #{project_name} | grep '^Revision:' | sed 's/Revision: //'].split[0].to_i + 1
  end
end
