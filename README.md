# Barcode Server

Sinatra application which generates barcode or QR Code images. 

Uses [Gnu Barcode](http://www.gnu.org/software/barcode/) via [gbarcode](http://gbarcode.rubyforge.org/) gem to generate _PostScript_ files and ImageMagick to convert to _PNG_ for generating barcodes.

Uses [libqrencode](http://fukuchi.org/works/qrencode/index.html.en) via [qrencoder](https://github.com/harrisj/qrencoder) gem to generate QR Codes.

## Usage

### Generating Barcodes

Get requests to `server.tld/barcode/<symbology>/<data>` will respond with an image in the requested symbology.

To generate a *CODE_39* image, make a GET request to `server.tld/barcode/39/DATA123456`.

Or, to generate a *CODE_128B* image, make a GET request to `server.tld/barcode/128b/DATA123456`.

Alternately, the *data* and *symbology* parameters can be supplied in the querystring, thus: `server.tld/barcode/128b?data=DATA123456` or `server.tld/barcode?symbology=128b&data=DATA123456`. This is useful when the barcode data contains characters which are illegal in the path section of a URL.

#### Symbology

Gnu Barcode supports several different encoding formats - know as a symbology. See [Wikipedia](http://en.wikipedia.org/wiki/Barcodes) for info on barcodes.

Supported symbologies in Gnu Barcode are:

  - CODE_128 
  - CODE_128RAW
  - CODE_128B 
  - CODE_128C 
  - CODE_EAN
  - CODE_UPC
  - CODE_ISBN
  - CODE_39
  - CODE_I25
  - CODE_CBR
  - CODE_MSI
  - CODE_PLS
 
Different symbologies support different charactersets and sized data packets. If the data sent for encoding is unsupported by the selected symbology, not file will be served (Gnu Barcode will fail).

#### Image size

You can supply additional parameters to alter the file that is produced. The following querystring parameters are accepted:

  - width
  - height
  - margin

The default width is __400__. The default height is __200__. The default margin is __10__.

#### Text label

By default there is no text included on the barcode image. You can add the text label by supplying the querystring parameter `text=1`.

### Generating QR Codes

Requests to `server.tld/qrcode/<data>` will respond with a QR Code image.

The data parameter can also be supplied in the querystring, thus:  `server.tld/qrcode?data=DATA123456` 

#### Version

There are 40 versions of [QR Code](http://en.wikipedia.org/wiki/QR_Code) which enable encoding of different volumes of data and enabling high levels of error correction. 

The version can be specified in the querystring by using the parameter `version`. This must be an integer between 1 and 40.

The default version in __4__. 

#### Image size

The image size can be controlled by specifying the number of pixels to be used per module. This is configurable with the querystring parameter `pixels_per_module`.

The default pixels per module is __6__.

## Deployment notes

Deployed with nginx/passenger. Be sure to install gems using `bundle install --deployment` so that passenger can find them.

Also set write permissions on `./generated_files/` directory so that passenger/nginx can write to it.

Ensure that GET requests can accept sufficient data lengths for larger QR Codes if you intend to support them.

## Credits

The implementation of service was influenced by the [barcode generator](https://github.com/anujluthra/barcode-generator) rails plugin by Anuj Luthra.
