coqdoc --parse-comments --toc --index qoqindex *.v x86/*.v charge/*.v x86/win/*.v x86/lib/regexp/*.v 
\cygwin\bin\tar cf ppdp2013.tar *.v *.el charge/*.v charge/*.el x86/*.v x86/*.el x86/win/*.v x86/win/*.el x86/lib/regexp/*.v x86/lib/regexp/*.el x86/bin/hexbin.exe x86/bin/iso_dir/iso.bin x86/bin/cdimage.exe x86/bin/etfs.bin Makefile.common README Makefile buildiso.bat build.bat GNUmakefile