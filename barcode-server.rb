require 'sinatra'
require 'gbarcode'
require 'cocaine'

require 'debugger'

DEFAULT_OPTIONS = {
	:encoding_format => DEFAULT_ENCODING, 
	:width => 400, 
	:height => 200, 
	:resolution => 150, 
	:antialias => false}

get '/favicon.ico' do
  send_file ''
end

get '/barcode/:symbology/:value' do
  opts = {:encoding_format => set_symbology(params[:symbology])}
  # querystring options
  opts[:width] = params[:width].to_i if params[:width]
  opts[:height] = params[:height].to_i if params[:height]
  opts[:scaling_factor].to_i if params[:scaling_factor]
  opts[:xoff] = params[:xoff].to_i if params[:xoff]
  opts[:yoff] = params[:yoff].to_i if params[:yoff]
  opts[:margin] = params[:margin].to_i if params[:margin]

  bc = barcode(params[:value], DEFAULT_OPTIONS.merge(opts)) 

  send_file bc, :type => :png

  File.delete(bc)
end


def barcode(id, options = DEFAULT_OPTIONS)

  path = "#{File.dirname(__FILE__)}/barcodes" 
  eps = "#{path}/#{id}.eps"
  out = "#{path}/#{id}.png"
      
  bc = Gbarcode.barcode_create(id)
  bc.width  = options[:width]          if options[:width]
  bc.height = options[:height]         if options[:height]
  bc.scalef = options[:scaling_factor] if options[:scaling_factor]
  bc.xoff   = options[:xoff]           if options[:xoff]
  bc.yoff   = options[:yoff]           if options[:yoff]
  bc.margin = options[:margin]         if options[:margin]
  Gbarcode.barcode_encode(bc, options[:encoding_format])

  if options[:no_ascii]
    print_options = Gbarcode::BARCODE_OUT_EPS|Gbarcode::BARCODE_NO_ASCII
  else
    print_options = Gbarcode::BARCODE_OUT_EPS
  end

  #encode the barcode object in desired format
  File.open(eps,'wb') do |eps_img| 
    Gbarcode.barcode_print(bc, eps_img, print_options)
    eps_img.close
    convert_to_png(eps, out, options[:resolution], options[:antialias])
  end
  File.delete(eps) 

  #return png file path
  out
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
  if !resolution.nil?
    options << "-density #{resolution}"
  elsif antialias == 1
    options << "+antialias" 
  end
  cmd = Cocaine::CommandLine.new("convert", "#{options.join(' ')} #{src} #{out}")
  cmd.run
end
