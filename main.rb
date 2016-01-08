require 'base64'
require 'rmagick'
require 'sinatra'
require 'teaas'

get '/' do
  haml :index
end

get '/marquee' do
  haml :marquee
end

get '/spin' do
  haml :spin
end

get '/turbo' do
  haml :turbo
end

def valid_input?(params)
  params['imagefile'] && params['imagefile'][:type].start_with?('image')
end

def turboize(img, turbo)
  img.delay = 1
  img.ticks_per_second = turbo
  img.iterations = 0
  img
end

post '/marquee' do
  if valid_input?(params)
    img_path = params['imagefile'][:tempfile].path

    marquee_image = Teaas::Marquee.marquee_from_file(img_path)

    blob_result = Teaas::Turboize.turbo(marquee_image, params['resize'])
    @result = blob_result.map { |i| Base64.encode64(i) }

    haml :result
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
    @result = blob_result.map { |i| Base64.encode64(i) }

    haml :result
  else
    haml :invalid_input
  end
end

post '/spin' do
  if valid_input?(params)
    img_path = params['imagefile'][:tempfile].path

    spinned_image = Teaas::Spin.spin_from_file(img_path)

    blob_result = Teaas::Turboize.turbo(spinned_image, params['resize'])
    @result = blob_result.map { |i| Base64.encode64(i) }

    haml :result
  else
    haml :invalid_input
  end
end
