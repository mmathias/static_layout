require "fileutils"

class VideoEncoder
  attr_reader :width, :height

  def initialize(path)
    @source = File.expand_path(path)
    @name = File.basename(@source, ".*")
    @out_dir = "#{File.dirname(@source)}/compressed"
    @width = 978
    @height = 611
  end

  def process
    compress "mp4" do |input, output|
      run "HandBrakeCLI -i '#{input}' -o '#{output}' -e x264  -b 300 -a 1 -E ca_aac -B 96 -6 mono -R Auto -D 0.0 -f mp4 -r 30 --strict-anamorphic -O -x 'b-adapt=2:rc-lookahead=50'"
    end

    compress "m4v" do |input, output|
      run "HandBrakeCLI -i '#{input}' -o '#{output}' -e x264  -q 20.0 -a 1 -E ca_aac -B 96 -6 mono -R Auto -D 0.0 -f mp4 --width #{width} --height #{height} -O -x 'cabac=0:ref=2:me=umh:bframes=0:weightp=0:subq=6:8x8dct=0:trellis=0'"
    end

    compress "ogv" do |input, output|
      run "ffmpeg2theora -v 8 -C 1 '#{input}' -o '#{output}'"
    end

    compress "webm" do |input, output|
      run "ffmpeg -pass 1 -passlogfile '#{output}' -keyint_min 0 -g 250 -skip_threshold 0 -qmin 1 -qmax 51 -i '#{input}' -vcodec libvpx -b 358400 -an -f webm -y NUL -threads 0"
      run "ffmpeg -pass 2 -passlogfile '#{output}' -keyint_min 0 -g 250 -skip_threshold 0 -qmin 1 -qmax 51 -i '#{input}' -vcodec libvpx -b 358400 -acodec libvorbis -ab 98304 -ac 1 -threads 0 -y '#{output}'"
      FileUtils.rm("NUL")
      FileUtils.rm("#{output}-0.log")
    end
  end

  def run(command)
    puts "Running: #{command}"
    system(command)
  end

  def compress(ext)
    out_file = "#{@out_dir}/#{@name}.#{ext}"

    if File.exist? out_file
      puts "Skipping #{@name} because compressed file already exists."
    else
      yield(@source, out_file)
    end
  end
end

VideoEncoder.new(ARGV.first).process
