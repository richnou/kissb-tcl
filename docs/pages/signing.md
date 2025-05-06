# Build Signature Verification

The packages we are distributed are provided with a SHA256 Checksum which is signed by our PGP Key:

**Key Email:** signing@kissb.dev<br/>
**Key Fingerprint:** E242 53BA 23A2 452F<br/>
<https://keys.openpgp.org/search?q=signing%40kissb.dev>

To verify a file, first import the key:

    $ gpg --recv-keys 0xE24253BA23A2452F

For a given downloaded file, download the signed checksum, calculate the checksum and verify the signature: 

    $ wget https://kissb.s3.de.io.cloud.ovh.net/tcl9/9.0.1/250501/tcl9-x86_64-redhat-linux-rhel8-shared-9.0.1.tar.gz
    $ wget https://kissb.s3.de.io.cloud.ovh.net/tcl9/9.0.1/250501/tcl9-x86_64-redhat-linux-rhel8-shared-9.0.1.tar.gz.sha256.asc

Now Calculate the sha256 and save it to a file:

    $ sha256sum -b tcl9-x86_64-redhat-linux-rhel8-shared-9.0.1.tar.gz > tcl9-x86_64-redhat-linux-rhel8-shared-9.0.1.tar.gz.sha256

Finally, verify the signature using gpg: 

    $ gpg --verify  tcl9-x86_64-redhat-linux-rhel8-shared-9.0.1.tar.gz.sha256.asc tcl9-x86_64-redhat-linux-rhel8-shared-9.0.1.tar.gz.sha256