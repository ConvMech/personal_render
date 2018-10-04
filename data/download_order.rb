require 'json'
require 'fileutils'

if ARGV.length < 2
  puts "run as: ruby download_order.rb {staging|production} {order_num} {username} {password} {order_download_folder(optional)}"
  puts "example: ruby download_order.rb production 118100 sarthak@hoverinc.com password /store1/order_jsons"
  exit
end

environment = ARGV[0]
order_id = ARGV[1]
if ARGV.length < 5
  storage_dir = Dir.pwd
else
  storage_dir = ARGV[4]
end

username = ARGV[2]
password = ARGV[3]
url = nil

if environment == "staging"
  url = "https://staging-manowar.hover.to/orders/#{order_id}.json"
  primitive_url = "https://staging-manowar.hover.to/orders/#{order_id}/primitive_input.json"
elsif environment == "production"
  url = "https://manowar.hover.to/orders/#{order_id}.json"
  primitive_url = "https://manowar.hover.to/orders/#{order_id}/primitive_input.json"
end

order_dir = "#{storage_dir}/order_#{order_id}"
order_json_path = "#{order_dir}/#{order_id}.json"
machete_json_path = "#{order_dir}/#{order_id}_machete.json"
primitive_json_path = "#{order_dir}/#{order_id}.lines.json"

# add two more for machete_data
machete_render_json_path = "#{order_dir}/machete.json"
model_render_json_path = "#{order_dir}/model_json_v3.json"

#`rm -rf #{order_dir}`

unless File.exist? order_dir
  `mkdir -p #{order_dir}`
end
#else
  # puts "order_dir exits, exiting download_order.rb"
   #exit
#end

`curl --user #{username}:#{password} #{url} > #{order_json_path}`
`curl --user #{username}:#{password} #{primitive_url} > #{primitive_json_path}`

f = File.open(order_json_path)
j = JSON.load(f)

image_ids = j["images"].map { |img| img["id"] }
machete_url = j['building_version']['machete_model_measurements']['url']

machete_render_url = j['building_version']['machete']['url']
model_json_v3_url = j['building_version']['model_json_v3']['url']

`curl '#{machete_url}' > #{machete_json_path}`
`curl '#{machete_render_url}' > #{machete_render_json_path}`
`curl '#{model_json_v3_url}' > #{model_render_json_path}`

image_ids.each do |image_id|
  image_url = nil
  if environment == "staging"
    image_url = "https://staging-manowar.hover.to/images/#{image_id}"
  elsif environment == "production"
    image_url = "https://manowar.hover.to/images/#{image_id}.jpg"
  end

  image_filename = "#{order_dir}/image_#{image_id}_order_#{order_id}.jpg"

  if not File.exists? image_filename
     puts image_filename
  else
    puts image_filename+" exists"
  end
  #puts Dir.pwd+image_filename[1..-1]
  #puts File.exists? Dir.pwd+image_filename[1..-1]

  if not File.exists?  image_filename
    `curl --user #{username}:#{password} -L #{image_url} > #{image_filename}`
  end

end
