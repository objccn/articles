require 'fileutils'
require 'net/http'

url_path = 'rake_task/data/urls'

def load_content (article_url)
	print "Loading... #{article_url}"
	uri = URI.parse("http://fuckyeahmarkdown.com/go/?u=" + article_url)
	res = Net::HTTP.get_response(uri)
	# Fix the wrong conversion of `[
	res.body.gsub '`[', '[`'
end

def write_to_file (issue_idx, article_idx, content)
	folder_path = "../origin//issue" + issue_idx;
  	FileUtils.mkdir_p(folder_path) unless File.directory?(folder_path)

  	file_path = folder_path + "/issue-" + issue_idx.to_s + "-" + article_idx.to_s + ".md"
  	File.open(file_path, 'w') { |file| file.write(content) }
  	puts "Writing to #{file_path}\n"
end

fileInfo = {}

File.open(url_path).read.each_line do |line|
	issue_match = /[0-9]+/.match(line)
	if issue_match
		issue_idx = issue_match[0]
		fileInfo[issue_idx] ? fileInfo[issue_idx] += 1 : fileInfo[issue_idx] = 0
		content = load_content(line)

		write_to_file(issue_idx, fileInfo[issue_idx], content)
	end
end

