# Barcode Server

Sinatra application which generates barcode images. Uses [Gnu Barcode](http://www.gnu.org/software/barcode/) via [gbarcode](http://gbarcode.rubyforge.org/) to generate _PostScript_ files and ImageMagick to convert to _PNG_.

## Usage

Get requests to `server.tld/barcode/<symbology>/<data>` will respond with an image in the requested symbology.

To generate a *CODE_39* image, make a GET request to `server.tld/barcode/39/DATA123456`.

Or, to generate a *CODE_128B* image, make a GET request to `server.tld/barcode/128b/DATA123456`.

Alternately, the *data* and *symbology* parameters can be supplied in the querystring, thus:  `server.tld/barcode/128b?data=DATA123456` or `server.tld/barcode?symbology=128b&data=DATA123456`. This is useful when the barcode data contains characters which are illegal in the path section of a URL.

### Querystring parameters

You can supply additional parameters to alter the file that is produced. The following querystring parameters are accepted and passed through to _gbarcode_:

  - width
  - height
  - margin

## Symbology

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

## Deployment notes

Deployed with nginx/passenger. Be sure to install gems using `bundle install --deployment` so that passenger can find them.

Also set write permissions on `./generated_files/` directory so that Passenger/Nginx can write to it.

## Credits

The implementation of service was informed by the [barcode generator](https://github.com/anujluthra/barcode-generator) rails plugin by Anuj Luthra.
