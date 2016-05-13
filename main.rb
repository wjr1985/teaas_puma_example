require 'aws-sdk'
require 'base64'
require 'dotenv'
require 'rmagick'
require 'sinatra'
require 'teaas'

Dotenv.load

get '/' do
  haml :index
end

get '/bloodify' do
  haml :bloodify
end

get '/fireify' do
  haml :fireify
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

get '/spin' do
  haml :spin
end

get '/tumbleweed' do
  haml :tumbleweed
end

get '/turbo' do
  haml :turbo
end

def valid_input?(params)
  params['imagefile'] && params['imagefile'][:type].start_with?('image') && File.size(params['imagefile'][:tempfile].path) <= 500000
end

def valid_spin_input?(params)
  params['rotations'].to_i <= 50 && valid_input?(params)
end

def turboize(img, turbo)
  img.delay = 1
  img.ticks_per_second = turbo
  img.iterations = 0
  img
end

post '/bloodify' do
  if valid_input?(params)
    img_path = params['imagefile'][:tempfile].path

    spinned_image = Teaas::Blood.blood_from_file(img_path)

    blob_result = Teaas::Turboize.turbo(spinned_image, params['resize'])
    _process_and_display_results(blob_result)
  else
    haml :invalid_input
  end
end

post '/fireify' do
  if valid_input?(params)
    img_path = params['imagefile'][:tempfile].path

    spinned_image = Teaas::Fire.fire_from_file(img_path)

    blob_result = Teaas::Turboize.turbo(spinned_image, params['resize'])
    _process_and_display_results(blob_result)

    haml :result
  else
    haml :invalid_input
  end
end


post '/intensify' do
  if valid_input?(params)
    img_path = params['imagefile'][:tempfile].path

    intensified_image = Teaas::Intensify.intensify_from_file(img_path)

    blob_result = Teaas::Turboize.turbo(intensified_image, params['resize'])
    _process_and_display_results(blob_result)
  else
    haml :invalid_input
  end
end

post '/marquee' do
  if valid_input?(params)
    img_path = params['imagefile'][:tempfile].path

    marquee_image = Teaas::Marquee.marquee_from_file(img_path, :reverse => params['reverse'])

    blob_result = Teaas::Turboize.turbo(marquee_image, params['resize'])
    _process_and_display_results(blob_result)
  else
    haml :invalid_input
  end
end

post '/parrotify' do
  if valid_input?(params)
    img_path = params['imagefile'][:tempfile].path

    parrotify_image = Teaas::Parrotify.parrotify_from_file(img_path)

    blob_result = Teaas::Turboize.turbo(parrotify_image, params['resize'], [1000], :delay => 40)

    blob_result << Magick::ImageList.new('public/parrot.gif').to_blob

    _process_and_display_results(blob_result)
  else
    haml :invalid_input
  end
end

post '/pulse' do
  if valid_input?(params)
    img_path = params['imagefile'][:tempfile].path

    spinned_image = Teaas::Pulse.pulse_from_file(img_path)

    blob_result = Teaas::Turboize.turbo(spinned_image, params['resize'])
    _process_and_display_results(blob_result)
  else
    haml :invalid_input
  end
end

post '/turbo' do
  if valid_input?(params)
    img_path = params['imagefile'][:tempfile].path

    if params['allspeeds']
      blob_result = Teaas::Turboize::turbo_from_file(img_path, params['resize'])
    else
      blob_result = Teaas::Turboize::turbo_from_file(img_path, params['resize'], [params['turbo'].to_i])
    end
    _process_and_display_results(blob_result)
  else
    haml :invalid_input
  end
end

post '/tumbleweed' do
  if valid_input?(params)
    img_path = params['imagefile'][:tempfile].path

    spin_image = Teaas::Spin.spin_from_file(img_path, :rotations => params['rotations'].to_i, :animate => true)
    marquee_image = Teaas::Marquee.marquee(spin_image)

    blob_result = Teaas::Turboize.turbo(marquee_image, params['resize'])
    _process_and_display_results(blob_result)
  else
    haml :invalid_input
  end
end

post '/spin' do
  if valid_spin_input?(params)
    img_path = params['imagefile'][:tempfile].path

    options = {}
    options[:rotations] = params['rotations'].to_i
    options[:counterclockwise] = true if params['counterclockwise']
    options[:animate] = true if params['animate']

    spinned_image = Teaas::Spin.spin_from_file(img_path, options)

    blob_result = Teaas::Turboize.turbo(spinned_image, params['resize'])
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
