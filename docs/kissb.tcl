

# Required:
# Required: apt-get install libcairo2-dev libfreetype6-dev libffi-dev libjpeg-dev libpng-dev libz-dev pngquant

set build.name "tcl9-docs"

package require flow.mkdocs 1.0

vars.set flow.mkdocs.presets -kissv2

flow.enableNetlify

node.init


files.cp ../scripts/tclshw pages/get/
files.cp ../scripts/wishw pages/get/
