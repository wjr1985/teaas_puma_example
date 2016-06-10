require 'aws-sdk'
require 'base64'
require 'dotenv'
require 'open-uri'
require 'rmagick'
require 'sinatra'
require 'teaas'

require_relative 'lib/magic_number'

Dotenv.load

# We always want OpenURI to return a tempfile
# http://stackoverflow.com/questions/694115/why-does-ruby-open-uris-open-return-a-stringio-in-my-unit-test-but-a-fileio-in
OpenURI::Buffer.send :remove_const, 'StringMax' if OpenURI::Buffer.const_defined?('StringMax')
OpenURI::Buffer.const_set 'StringMax', 0

get '/' do
  haml :index
end

get '/bloodify' do
  haml :bloodify
end

get '/fireify' do
  haml :fireify
end

get '/gotify' do
  haml :gotify
end

get '/intensify' do
  haml :intensify
end

get '/marquee' do
  haml :marquee
end

get '/parrotify' do
  haml :parrotify
end

get '/pulse' do
  haml :pulse
end

get '/resize' do
  haml :resize
end

get '/spin' do
  haml :spin
end

get '/tumbleweed' do
  haml :tumbleweed
end

get '/turbo' do
  haml :turbo
end

def valid_image_input?(params)
  params['imagefile'] && params['imagefile'][:type].start_with?('image') && File.size(params['imagefile'][:tempfile].path) <= 500000
end

def valid_url_input?(url)
  URI.parse(url).kind_of?(URI::HTTP)
end

def valid_spin_input?(params)
  params['rotations'].to_i <= 50
end

def turboize(img, turbo)
  img.delay = 1
  img.ticks_per_second = turbo
  img.iterations = 0
  img
end

post '/bloodify' do
  img_path = _read_image(params)
  if img_path
    blood_image = Teaas::Blood.blood_from_file(img_path)

    blob_result = _default_turbo(blood_image, params)
    _process_and_display_results(blob_result)
  else
    haml :invalid_input
  end
end

post '/fireify' do
  img_path = _read_image(params)
  if img_path
    fire_image = Teaas::Fire.fire_from_file(img_path)

    blob_result = _default_turbo(fire_image, params)
    _process_and_display_results(blob_result)

    haml :result
  else
    haml :invalid_input
  end
end

post '/gotify' do
  img_path = _read_image(params)
  if img_path
    fire_image = Teaas::Got.got_from_file(img_path)

    blob_result = _default_turbo(fire_image, params)
    _process_and_display_results(blob_result)

    haml :result
  else
    haml :invalid_input
  end
end


post '/intensify' do
  img_path = _read_image(params)
  if img_path
    intensified_image = Teaas::Intensify.intensify_from_file(img_path)

    blob_result = _default_turbo(intensified_image, params)
    _process_and_display_results(blob_result)
  else
    haml :invalid_input
  end
end

post '/marquee' do
  img_path = _read_image(params)
  if img_path
    marquee_image = Teaas::Marquee.marquee_from_file(img_path, :reverse => params['reverse'])

    blob_result = _default_turbo(marquee_image, params)
    _process_and_display_results(blob_result)
  else
    haml :invalid_input
  end
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
    haml :invalid_input
  end
end

post '/pulse' do
  img_path = _read_image(params)
  if img_path
    pulsed_image = Teaas::Pulse.pulse_from_file(img_path)

    blob_result = _default_turbo(pulsed_image, params)
    _process_and_display_results(blob_result)
  else
    haml :invalid_input
  end
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
    haml :invalid_input
  end
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
    haml :invalid_input
  end
end

post '/tumbleweed' do
  img_path = _read_image(params)
  if img_path
    spin_image = Teaas::Spin.spin_from_file(img_path, :rotations => params['rotations'].to_i, :animate => true)
    marquee_image = Teaas::Marquee.marquee(spin_image)

    blob_result = _default_turbo(marquee_image, params)
    _process_and_display_results(blob_result)
  else
    haml :invalid_input
  end
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
    haml :invalid_input
  end
end

def _process_and_display_results(blob_result)
  if ENV['AWS_S3_BUCKET_NAME']
    @result = _upload_to_s3(blob_result)
  else
    @result = blob_result.map { |i| Base64.encode64(i) }
  end

  haml :result
end

def _upload_to_s3(blob_result)
  s3 = Aws::S3::Resource.new
  bucket = s3.bucket(ENV['AWS_S3_BUCKET_NAME'])
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

def _read_image(params)
  img_path = nil
  if valid_image_input?(params)
    img_path = params['imagefile'][:tempfile].path
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
