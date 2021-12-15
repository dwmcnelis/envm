require "option_parser"

list = false
current = false
use = false
test = false
env = "dev"

parser = OptionParser.new do |parser|
  parser.banner = "Manage .env versions"

  parser.on "-v", "--version", "Show version" do
    puts "version 1.0"
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

	parser.on("test", "Test things") do
    test = true
    parser.banner = "Usage: envm test env"
		env = ARGV[1]
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

if test
	loadPartials(env)
elsif list
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
	File.read(file).split("\n")
end

def parse(lines)
	parsed = {} of String => String
	lines.each do |line|
		parts = line.split("=").map { |part| part.strip }
		if parts.size === 2
			key = parts[0]
			value = parts[1]
			parsed[key] = value
		end
	end
	parsed
end

def render(content)
	rendered = [] of String
	content.each do |key, value|
		rendered.push("#{key}=#{value}")
	end
	rendered
end


def loadPartials(env)
	files = Dir.glob(".env.#{env}*" , match_hidden: true).sort
	base_files = files.select { |file| file === ".env.#{env}" }
	base_file = if base_files.size === 1
	 base_files.pop
	end
	partial_files = files.reject { |file| file === ".env.#{env}" }
	content = if base_file 
		parse(load(base_file))
	end || {} of String => String
	partial_files.each do |partial_file|
		partial = parse(load(partial_file))
		partial.each do |key, value|
			content[key] = value
		end
	end
	render(content)
end

def save(lines, file)
	File.write(file, lines.join("\n"))
end

def strip(lines)
	lines.reject { |line| line.starts_with?("ENVM=") } 
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
