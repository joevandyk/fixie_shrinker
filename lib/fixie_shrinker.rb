require 'open3'
module FixieShrinker
  
  YUI = "#{File.dirname(__FILE__)}/yuicompressor-2.4.2.jar"
  
  mattr_accessor :environments
  self.environments = %w(development)

  def compress_and_include_javascripts(compressed_file_name, *javascripts)
    compress_to javascript_path(compressed_file_name), *(javascripts.map { |j| javascript_path(j) })
    javascript_include_tag compressed_file_name
  end
  
  def compress_and_include_stylesheets(compressed_file_name, *stylesheets)
    compress_to stylesheet_path(compressed_file_name), *stylesheets.map { |s| stylesheet_path(s) }
    stylesheet_link_tag compressed_file_name
  end
  
  private
  
  def compress?
    environments.include?(RAILS_ENV)
  end

  def path_without_timestamp path
    path.gsub(/\?.*/, '')
  end
  
  def compress_to(compressed_file_name, *sources)
    sources.map! { |j| path_without_timestamp(j) } 
    if compress?
      concat = sources.map { |source| File.read(File.join(RAILS_ROOT, 'public', source)) }.join

      final_path = File.join(RAILS_ROOT, 'public', path_without_timestamp(compressed_file_name))

      FileUtils.mkdir_p File.join(RAILS_ROOT, 'tmp')
      tmp_filename = File.join(RAILS_ROOT, 'tmp', File.basename(final_path))

      if !File.exist?(tmp_filename) or !File.exist?(final_path) or File.read(tmp_filename) != concat
        File.open(tmp_filename, 'w+') { |f| f << concat }
        command = "java -jar #{YUI} #{tmp_filename} -o #{final_path}"
        Open3::popen3(command) do |stdin, stdout, stderr|
          if error = stderr.read and !error.blank?
            File.delete(final_path) if File.exist?(final_path)
            raise "YUI COMPRESSOR ERROR: #{ error }"
          end
        end
      end
    end
  end
end
