all:
	perl generate-docset.pl
	rm -fr /home/yanick/.local/share/zeal/docsets/updeep.docset
	cp -r updeep.docset /home/yanick/.local/share/zeal/docsets
