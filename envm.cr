require "option_parser"

list = false
current = false
use = false
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
	File.read(file).split("\n")
end

def save(lines, file)
	File.write(file, lines.join("\n"))
end

def strip(lines)
	lines.reject { |line| line.starts_with?("ENVM=") } 
end

def backup(file)
	save(load(file), "#{file}~")
end

def use(env)
	save(strip(load(".env.#{env}")).unshift("ENVM=#{env}\n"), ".env")
end

def id(file)
	ids = load(file).select { |line| line.starts_with?("ENVM=") }.map { |line| line.gsub("ENVM=", "") }
	if ids.size === 1
		ids.pop
	end
end
