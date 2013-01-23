require 'sinatra/base'
require 'gbarcode'
require 'cocaine'
require 'redcarpet'
require 'fileutils'
require 'digest/md5'
require 'qrencoder'

require 'debugger'

class BarcodeServer < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  DEFAULT_BARCODE_OPTIONS = {
    :width => 400, 
    :height => 200, 
    :margin => 0,
    :resolution => 72, 
    :antialias => false}

  DEFAULT_QRCODE_OPTIONS = {
    :version => 4,
    :pixels_per_module => 6}


  get '/favicon.ico' do
    send_file 'img/1px.gif'
  end

  get '/barcode/?:symbology?/?:data?/?' do
    halt 400 unless params[:data]  

    symbology = set_symbology(params[:symbology])
    opts = {:encoding_format => symbology}.merge(collect_opts([:width, :height, :margin, :text]))

    bc = generate_barcode(params[:data], DEFAULT_BARCODE_OPTIONS.merge(opts)) 
    send_file bc, :type => :png

    File.delete(bc)
  end

  get '/qrcode/?:data?/?' do
    halt 400 unless params[:data]  

    opts = collect_opts([:version, :pixels_per_module])
    png = generate_qrcode(params[:data], DEFAULT_QRCODE_OPTIONS.merge(opts))
       
    send_file png
  end

  get '/info' do
    rm = File.new("README.md","rb")
    erb markdown(rm.read)
  end

  def collect_opts(options)
    options.inject({}) do |opts,param|
      opts[param] = params[param].to_i if params[param]
      opts
    end
  end

  def get_path
    date_stamp = Time.now.strftime("%Y%m%d").to_i 
    file_path = "#{File.dirname(__FILE__)}/../generated_files/#{date_stamp}/" 
    FileUtils.makedirs file_path
    file_path
  end

  def generate_qrcode(data, options)
    file = Digest::MD5.hexdigest(data)
    png = "#{get_path}/#{file}.png"
  
    qrcode = QREncoder.encode(data, {:version => options[:version]})
    qrcode.png({:pixels_per_module => options[:pixels_per_module]}).save(png)

    png # return png file path
  end

  def generate_barcode(data, options)
    path = get_path
    file = Digest::MD5.hexdigest(data)
    eps = "#{path}/#{file}.eps"
    png = "#{path}/#{file}.png"
        
    bc = Gbarcode.barcode_create(data)
    bc.width  = options[:width] if options[:width]
    bc.height = options[:height] if options[:height]
    bc.margin = options[:margin] if options[:margin]
    Gbarcode.barcode_encode(bc, options[:encoding_format])

    #encode the barcode object with specified symbology
    File.open(eps,'wb') do |eps_file| 
      Gbarcode.barcode_print(bc, eps_file, Gbarcode::BARCODE_OUT_EPS | (options[:text]==1 ? 0 : Gbarcode::BARCODE_NO_ASCII))
      eps_file.close
      convert_to_png(eps, png, options[:resolution], options[:antialias])
    end
    File.delete(eps) 
    
    png # return png file path
  end

  def set_symbology(fmt)
    if fmt =~ /^128$/
      Gbarcode::BARCODE_128 
    elsif fmt =~ /^128RAW$/i
      Gbarcode::BARCODE_128RAW
    elsif fmt =~ /^128B$/i
      Gbarcode::BARCODE_128B 
    elsif fmt =~ /^128C$/i
      Gbarcode::BARCODE_128C 
    elsif fmt =~ /^EAN$/i
      Gbarcode::BARCODE_EAN
    elsif fmt =~ /^UPC$/i
      Gbarcode::BARCODE_UPC
    elsif fmt =~ /^ISBN$/i
      Gbarcode::BARCODE_ISBN
    elsif fmt =~ /^39$/
      Gbarcode::BARCODE_39
    elsif fmt =~ /^I25$/i
      Gbarcode::BARCODE_I25
    elsif fmt =~ /^CBR$/i
      Gbarcode::BARCODE_CBR
    elsif fmt =~ /^MSI$/i
      Gbarcode::BARCODE_MSI
    elsif fmt =~ /^PLS$/i
      Gbarcode::BARCODE_PLS
    else
      Gbarcode::BARCODE_NO_CHECKSUM
    end
  end

  # call imagemagick via system command 
  def convert_to_png(src, out, resolution=nil, antialias=nil)
    options = []
    options << "-density #{resolution}" if !resolution.nil?
    options << "+antialias" if antialias == 1
    cmd = Cocaine::CommandLine.new("convert", "#{options.join(' ')} #{src} #{out}")
    cmd.run
  end

  # start the server if ruby file executed directly
  run! if app_file == $0

end
