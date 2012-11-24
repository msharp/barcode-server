require 'sinatra/base'
require 'gbarcode'
require 'cocaine'
require 'redcarpet'
require 'fileutils'

require 'debugger'

class BarcodeServer < Sinatra::Base

  DEFAULT_OPTIONS = {
    :width => 400, 
    :height => 200, 
    :resolution => 150, 
    :antialias => false}

  get '/favicon.ico' do
    send_file 'img/1px.gif'
  end

  get '/barcode/:symbology/:data' do
    opts = {:encoding_format => set_symbology(params[:symbology])}

    # querystring options
    opts[:width] = params[:width].to_i if params[:width]
    opts[:height] = params[:height].to_i if params[:height]
    opts[:scaling_factor].to_i if params[:scaling_factor]
    opts[:xoff] = params[:xoff].to_i if params[:xoff]
    opts[:yoff] = params[:yoff].to_i if params[:yoff]
    opts[:margin] = params[:margin].to_i if params[:margin]

    bc = generate_barcode(params[:data], DEFAULT_OPTIONS.merge(opts)) 
    send_file bc, :type => :png

    File.delete(bc)
  end

  get '*' do
    rm = File.new("README.md","rb")
    erb markdown(rm.read)
  end

  def get_path
    date_stamp = Time.now.strftime("%Y%m%d").to_i 
    file_path = "#{File.dirname(__FILE__)}/../generated_files/#{date_stamp}/" 
    FileUtils.makedirs file_path
    file_path
  end

  def generate_barcode(data, options = DEFAULT_OPTIONS)

    path = get_path
    eps = "#{path}/#{data}.eps"
    png = "#{path}/#{data}.png"
        
    bc = Gbarcode.barcode_create(data)
    bc.width  = options[:width]          if options[:width]
    bc.height = options[:height]         if options[:height]
    bc.xoff   = options[:xoff]           if options[:xoff]
    bc.yoff   = options[:yoff]           if options[:yoff]
    bc.scalef = options[:scaling_factor] if options[:scaling_factor]
    bc.margin = options[:margin]         if options[:margin]
    Gbarcode.barcode_encode(bc, options[:encoding_format])

    #encode the barcode object with specified symbology
    File.open(eps,'wb') do |eps_file| 
      Gbarcode.barcode_print(bc, eps_file, Gbarcode::BARCODE_OUT_EPS)
      eps_file.close
      convert_to_png(eps, png, options[:resolution], options[:antialias])
    end
    File.delete(eps) 
    #return png file path
    png
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
