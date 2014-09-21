{ stdenv, fetchurl, mvnBuild }:

mvnBuild rec {
  version = "1.8.1";
  name    = "commons-compress-${version}";

  src = fetchurl {
    url    = "mirror://apache/commons/compress/sources/${name}-src.tar.gz";
    sha256 = "11viabgf34r3zx1avj51n00hzmx89kym3i90l6a5v6dbfh61h0lp";
  };

  meta = with stdenv.lib; {
    homepage    = "http://commons.apache.org/proper/commons-compress";
    description = "Allows manipulation of ar, cpio, Unix dump, tar, zip, gzip, XZ, Pack200, bzip2, 7z, arj, lzma, snappy, DEFLATE and Z files.";
    maintainers = with maintainers; [ copumpkin ];
    license     = licenses.asl20;
  };
}
