require 'aws-sdk'
require 'base64'
require 'dotenv'
require 'json'
require 'open-uri'
require 'rmagick'
require 'sinatra'
require 'teaas'

require_relative 'lib/magic_number'

set :bind, '0.0.0.0'

Dotenv.load

# We always want OpenURI to return a tempfile
# http://stackoverflow.com/questions/694115/why-does-ruby-open-uris-open-return-a-stringio-in-my-unit-test-but-a-fileio-in
OpenURI::Buffer.send :remove_const, 'StringMax' if OpenURI::Buffer.const_defined?('StringMax')
OpenURI::Buffer.const_set 'StringMax', 0

["appendify", "bloodify", "customoverlayer", "fireify", "gotify", "intensify", "magrittify", "marquee", "mirror", "noify", "parrotify", "pulse", "resize", "reverse", "shakefistify", "spin", "tearsify", "think", "tumbleweed", "turbo", "waitify"].each do |route|
  get "/#{route}" do
    erb route.to_sym
  end
end

get '/' do
  erb :index
end

def valid_image_input?(params, image_param_name = 'imagefile')
  params[image_param_name] && params[image_param_name][:type].start_with?('image') && File.size(params[image_param_name][:tempfile].path) <= 500000
end

def valid_url_input?(url)
  URI.parse(url).kind_of?(URI::HTTP)
end

def valid_spin_input?(params)
  params['rotations'].to_i <= 50
end

post '/appendify' do
  if ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
    _lambda_appendify_post("appender", params)
  else
    erb :not_available
  end
end

post '/bloodify' do
  if ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY'] && false # we don't want to use this at all yet
    _lambda_overlayer_post("overlayer", params)
  else
    _generic_post(Teaas::Blood, "blood", params)
  end
end

post '/check_status' do
  @s3 ||= Aws::S3::Resource.new
  bucket = @s3.bucket("#{ENV['AWS_S3_BUCKET_NAME']}-processed")
  filename = params[:upload_filename]
  forwarded_params = params[:forwarded_params]

  obj = bucket.object(filename)
  if obj.exists?
    tempfile = Tempfile.new("transformed_image")
    obj.get(:response_target => tempfile)
    if _custom_resize?(forwarded_params)
      resize = "#{forwarded_params['resizex']}x#{forwarded_params['resizey']}"
    else
      resize = forwarded_params['resize']
    end

    blob_result = Teaas::Turboize::turbo_from_file(tempfile.path, resize, nil, :sample => forwarded_params['sample'])

    tempfile.close
    tempfile.unlink

    _process_and_display_results(blob_result)
  else
    erb :pleasewait, :locals => {:upload_filename => filename, :params => forwarded_params}
  end
end

post '/customoverlayer' do
  if ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
    _lambda_overlayer_post("overlayer", params)
  else
    erb :not_available
  end
end

post '/fireify' do
  _generic_post(Teaas::Fire, "fire", params)
end

post '/gotify' do
  _generic_post(Teaas::Got, "got", params)
end


post '/intensify' do
  _generic_post(Teaas::Intensify, "intensify", params)
end

post '/magrittify' do
  _generic_post(Teaas::Magrittify, "magrittify", params)
end

post '/marquee' do
  img_path = _read_image(params)
  if img_path
    case params['marquee_direction']
    when 'r'
      reverse = false
      horizontal = true
    when 'l'
      reverse = true
      horizontal = true
    when 'u'
      reverse = true
      horizontal = false
    when 'd'
      reverse = false
      horizontal = false
    else
      reverse = false
      horizontal = false
    end

    marquee_image = Teaas::Marquee.marquee_from_file(
      img_path,
      :reverse => reverse,
      :horizontal => horizontal,
      :crop => params['crop'],
    )

    blob_result = _default_turbo(marquee_image, params)
    _process_and_display_results(blob_result)
  else
    erb :invalid_input
  end
end

post '/mirror' do
  _generic_post(Teaas::Mirror, "mirror", params)
end

post '/noify' do
  _generic_post(Teaas::No, "no", params)
end

post '/parrotify' do
  img_path = _read_image(params)
  if img_path
    parrotify_image = Teaas::Parrotify.parrotify_from_file(img_path)

    resize = nil
    if _custom_resize?(params)
      resize = "#{params['resizex']}x#{params['resizey']}"
    else
      resize = params['resize']
    end

    blob_result = Teaas::Turboize.turbo(parrotify_image, resize, [1000], :delay => 40, :sample => params['sample'])

    blob_result << Magick::ImageList.new('public/parrot.gif').to_blob

    _process_and_display_results(blob_result)
  else
    erb :invalid_input
  end
end

post '/pulse' do
  _generic_post(Teaas::Pulse, "pulse", params)
end

post '/resize' do
  img_path = _read_image(params)
  if img_path
    resize = nil
    if _custom_resize?(params)
      resize = "#{params['resizex']}x#{params['resizey']}"
    else
      resize = params['resize']
    end
    blob_result = []
    blob_result << Teaas::Resize.resize_from_file(img_path, resize, :sample => params['sample']).to_blob

    _process_and_display_results(blob_result)
  else
    erb :invalid_input
  end
end

post '/reverse' do
  _generic_post(Teaas::Reverse, "reverse", params)
end

post '/shakefistify' do
  _generic_post(Teaas::ShakeFist, "shake_fist", params)
end

post '/tearsify' do
  _generic_post(Teaas::Tears, "tears", params)
end

post '/turbo' do
  img_path = _read_image(params)
  if img_path
    resize = nil
    if _custom_resize?(params)
      resize = "#{params['resizex']}x#{params['resizey']}"
    else
      resize = params['resize']
    end

    if params['allspeeds']
      blob_result = Teaas::Turboize::turbo_from_file(img_path, resize, nil, :sample => params['sample'])
    else
      blob_result = Teaas::Turboize::turbo_from_file(img_path, resize, [params['turbo'].to_i], :sample => params['sample'])
    end
    _process_and_display_results(blob_result)
  else
    erb :invalid_input
  end
end

post '/think' do
  _generic_post(Teaas::Think, "think", params)
end

post '/tumbleweed' do
  img_path = _read_image(params)
  if img_path
    spin_image = Teaas::Spin.spin_from_file(img_path, :rotations => params['rotations'].to_i, :animate => true)
    marquee_image = Teaas::Marquee.marquee(spin_image)

    blob_result = _default_turbo(marquee_image, params)
    _process_and_display_results(blob_result)
  else
    erb :invalid_input
  end
end

post '/waitify' do
  _generic_post(Teaas::Wait, "wait", params)
end

post '/spin' do
  img_path = _read_image(params)
  if img_path && valid_spin_input?(params)
    options = {}
    options[:rotations] = params['rotations'].to_i
    options[:counterclockwise] = true if params['counterclockwise']
    options[:animate] = true if params['animate']

    spinned_image = Teaas::Spin.spin_from_file(img_path, options)

    blob_result = _default_turbo(spinned_image, params)
    _process_and_display_results(blob_result)
  else
    erb :invalid_input
  end
end

def _generic_post(teaas_class, method_prefix, params)
  img_path = _read_image(params)
  if img_path
    image = teaas_class.send("#{method_prefix}_from_file", img_path)

    blob_result = _default_turbo(image, params)
    _process_and_display_results(blob_result)
  else
    erb :invalid_input
  end
end

def _lambda_overlayer_post(action, params)
  @s3 ||= Aws::S3::Resource.new
  bucket = @s3.bucket(ENV['AWS_S3_BUCKET_NAME'])
  img_path = _read_image(params)
  second_image_path = _read_image(params, "second_imagefile")
  source_filename = "#{SecureRandom.uuid}#{File.extname(img_path)}"
  second_source_filename = "#{SecureRandom.uuid}#{File.extname(second_image_path)}"
  upload_filename = "#{SecureRandom.urlsafe_base64}.gif"
  obj = bucket.object("emojis_to_process/#{source_filename}")
  obj.put(:body => File.new(img_path), :acl => 'public-read')

  obj = bucket.object("emojis_to_process/#{second_source_filename}")
  obj.put(:body => File.new(second_image_path), :acl => 'public-read')

  lambda_params = {
    "Records" => [
      {
        "s3" => {
          "object" => {
            "prefix" => "emojis_to_process",
            "key" => source_filename,
            "overlayer_key" => second_source_filename,
          },
          "bucket" => {
            "name" => "teaas",
          }
        },
        "action" => action,
        "upload_filename" => upload_filename,
      }
    ]
  }.to_json

  _common_lambda(params, lambda_params, upload_filename)
end

def _lambda_appendify_post(action, params)
  @s3 ||= Aws::S3::Resource.new
  bucket = @s3.bucket(ENV['AWS_S3_BUCKET_NAME'])
  img_path = _read_image(params)
  second_image_path = _read_image(params, "second_imagefile")
  source_filename = "#{SecureRandom.uuid}#{File.extname(img_path)}"
  second_source_filename = "#{SecureRandom.uuid}#{File.extname(second_image_path)}"
  upload_filename = "#{SecureRandom.urlsafe_base64}.gif"
  obj = bucket.object("emojis_to_process/#{source_filename}")
  obj.put(:body => File.new(img_path), :acl => 'public-read')

  obj = bucket.object("emojis_to_process/#{second_source_filename}")
  obj.put(:body => File.new(second_image_path), :acl => 'public-read')

  lambda_params = {
    "Records" => [
      {
        "s3" => {
          "object" => {
            "prefix" => "emojis_to_process",
            "key" => source_filename,
            "second_image" => second_source_filename,
          },
          "bucket" => {
            "name" => "teaas",
          }
        },
        "action" => action,
        "upload_filename" => upload_filename,
      }
    ]
  }.to_json

  _common_lambda(params, lambda_params, upload_filename)
end

def _common_lambda(params, payload, upload_filename)
  lambda_client = Aws::Lambda::Client.new(:region => 'us-east-1')
  resp = lambda_client.invoke(
    :function_name => "teaasJobs",
    :invocation_type => "Event",
    :log_type => "None",
    :payload => payload,
  )

  erb :pleasewait, :locals => {:upload_filename => upload_filename, :params => params}
end

def _process_and_display_results(blob_result)
  if ENV['UPLOAD_FILES_TO_AWS_S3']
    @result = _upload_to_s3(blob_result)
  else
    @result = blob_result.map { |i| Base64.encode64(i) }
  end

  erb :result
end

def _upload_to_s3(blob_result)
  @s3 ||= Aws::S3::Resource.new
  bucket = @s3.bucket(ENV['AWS_S3_BUCKET_NAME'])
  blob_result.map do |res|
    obj = bucket.object("emojis/#{SecureRandom.uuid}.gif")
    obj.put(:body => res, :acl => 'public-read')
    obj.public_url
  end
end

def _default_turbo(image, params)
  resize = nil
  if _custom_resize?(params)
    resize = "#{params['resizex']}x#{params['resizey']}"
  else
    resize = params['resize']
  end

  blob_result = Teaas::Turboize.turbo(image, resize, nil, :sample => params['sample'])
end

def _read_image(params, image_param_name = 'imagefile')
  img_path = nil
  if valid_image_input?(params, image_param_name)
    img_path = params[image_param_name][:tempfile].path
  elsif valid_url_input?(params['fileurl'])
    begin
      file = open(params['fileurl'])
      if _acceptable_image_type(file.path)
        img_path = file.path
      end
    rescue OpenURI::HTTPError
    end
  end
  img_path
end

def _acceptable_image_type(path)
  file = File.open(path, 'rb')
  header = file.read(4)
  valid_image = MagicNumber.gif?(header) || MagicNumber.jpg?(header) || MagicNumber.png?(header)
  file.close

  valid_image
end

def _custom_resize?(params)
  if params['resizex'] && params['resizey'] && !params['resizex'].empty? && !params['resizey'].empty? && params['resize'] == "custom"
    true
  else
    false
  end
end
