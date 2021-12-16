require "option_parser"

version = "1.0.0"
list = false
current = false
use = false
env = "dev"

parser = OptionParser.new do |parser|
  parser.banner = "Manage .env versions"

  parser.on "-v", "--version", "Show version" do
    puts "version #{version}"
    exit
  end
  
	parser.on "-h", "--help", "Show help" do
		puts parser
		exit
  end

	parser.on("list", "List .env versions") do
    list = true
    parser.banner = "Usage: envm list"
  end

	parser.on("current", "Show current .env version") do
    current = true
    parser.banner = "Usage: envm current"
  end

	parser.on("use", "Use a .env version") do
    use = true
		if (ARGV.size != 2)
			STDERR.puts "ERROR: invalid argument."
			STDERR.puts parser
			exit(1)
		end
		env = ARGV[1]

    parser.banner = "Usage: envm use <env>"
  end
	
	parser.missing_option do |option_flag|
    STDERR.puts "ERROR: #{option_flag} is missing something."
    STDERR.puts ""
    STDERR.puts parser
    exit(1)
  end

  parser.invalid_option do |option_flag|
    STDERR.puts "ERROR: #{option_flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

parser.parse

if list
	list_envs
elsif current
  current_env
elsif use
  use_env(env)
else
  puts parser
  exit(1)
end

def list_envs
	STDOUT.puts list.sort.join("\n")
end

def current_env
	current = id(".env")
	if current
		STDOUT.puts current
	else
		STDERR.puts "current version unknown!"
	end
end

def use_env(env)
	if list.includes?(env)
		backup(".env")
		use(env)
		STDOUT.puts "using #{env}"
	else
		STDERR.puts "#{env} version not found!"  
	end
end

def list
	Dir.glob(".env.*", match_hidden: true).map { |line| "#{line.gsub(".env.", "")}" }
end

def load(file)
	if File.exists?(file)
		File.read(file).split("\n")
	else
		[] of String
	end
end

def envar?(line)
	str = line.strip()
	str.match(/.*\=.*/)
end

def comment?(line)
	str = line.strip()
	str.starts_with?("#")
end

def blank?(line)
	str = line.strip()
	str === ""
end

def parse(line)
	str = line.strip()
	if /(.*)\=(.*)/ =~ str
		[$1, $2]
	else
		[nil, nil]
	end
end

def merge(candidate_line, content)
	if envar?(candidate_line)
		candidate_envar, candidate_value = parse(candidate_line)
		found = false
		content.each_with_index do |content_line, index|
			if envar?(content_line)
				content_envar, content_value = parse(content_line)
				if candidate_envar === content_envar
					found = true
					content[index] = "#{candidate_envar}=#{candidate_value}"
				end
			end
		end
		if !found
			content.push("#{candidate_envar}=#{candidate_value}")
		end
	elsif blank?(candidate_line) || comment?(candidate_line)
		content.push(candidate_line)
	end
end

def loadPartials(env)
	files = Dir.glob(".env.#{env}*" , match_hidden: true).sort
	base_files = files.select { |file| file === ".env.#{env}" }
	base_file = if base_files.size === 1
	 base_files.pop
	end
	partial_files = files.reject { |file| file === ".env.#{env}" }
	content = if base_file 
		load(base_file)
	end || [] of String
	partial_files.each do |partial_file|
		partial = load(partial_file)
		partial.each do |line|
			merge(line, content)
		end
	end
	content
end

def save(lines, file)
	File.write(file, lines.join("\n"))
end

def strip(lines)
	(lines || [] of String).reject { |line| line.starts_with?("ENVM=") } 
end

def backup(file)
	if File.exists?(file)
		save(load(file), "#{file}~")
	end
end

def use(env)
	save(strip(loadPartials(env)).unshift("ENVM=#{env}\n"), ".env")
end

def id(file)
	ids = load(file).select { |line| line.starts_with?("ENVM=") }.map { |line| line.gsub("ENVM=", "") }
	if ids.size === 1
		ids.pop
	end
end
