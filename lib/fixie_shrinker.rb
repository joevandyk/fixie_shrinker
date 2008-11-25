require 'open3'
module FixieShrinker
  
  class YUI_Error < RuntimeError; end
  YUI = "#{File.dirname(__FILE__)}/yuicompressor-2.4.2.jar"
  
  mattr_accessor :environments
  self.environments = %w(development)

  def compress_and_include_javascripts(compressed_file_name, *javascripts)
    compress_to javascript_path(compressed_file_name), *(javascripts.map { |j| javascript_path(j) })
    `rm -rf #{RAILS_ROOT}/public/javascripts/*fixie_shrinked_for_debugging*`
    javascript_include_tag compressed_file_name
  rescue YUI_Error => e
    javascripts.map { |file|
      begin 
        compress_to javascript_path("fixie_shrinked_for_debugging--" + file), javascript_path(file)
        javascript_include_tag("fixie_shrinked_for_debugging--" + file) 
      rescue YUI_Error => f
        javascript_include_tag(file) + report_error(f)
      end
    }.join
  end
  
  def compress_and_include_stylesheets(compressed_file_name, *stylesheets)
    compress_to stylesheet_path(compressed_file_name), *stylesheets.map { |s| stylesheet_path(s) }
    stylesheet_link_tag compressed_file_name
  rescue YUI_Error => e
    stylesheet_link_tag(*stylesheets) + report_error(e)
  end
  
  private

  def report_error exception
    javascript_tag("alert('Fixie Shrinker noticed bad code!  See console.log in browser for details.')") +
      javascript_tag("console.log('#{escape_javascript(exception.message)}')")
  end
  
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
            raise YUI_Error.new("YUI COMPRESSOR ERROR on <#{compressed_file_name}>: #{ error }")
          end
        end
      end
    end
  end
end
