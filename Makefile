################################################################################
#	Makefile for cheat.sh
#
#	Technically, no 'making' occurs, since it's just a shell script, but
#	let us not quibble over trivialities such as these.
################################################################################
ROOTPATH=
PREFIX=$(ROOTPATH)/usr
SRC=src
SRCFILE=cheat.sh
DESTFILE=cheat
DOC=doc
DATA=data
MANPATH=$(PREFIX)/share/man/man1
DATAPATH=$(PREFIX)/share/cheat
SHEETPATH=$(DATAPATH)/sheets

install:
	install -D -m 0755 $(SRC)/$(SRCFILE) $(PREFIX)/bin/$(DESTFILE)
	mkdir -p $(DATAPATH)
	cp -rv $(DATA) $(SHEETPATH)
	install -v -D -m 0644 LICENSE $(DATAPATH)/LICENSE
	install -v -D -m 0644 README $(DATAPATH)/README
	#install -D -g 0 -o 0 -m 0644 $(DOC)/cheat.1 $(MANPATH)/cheat.1

uninstall:
	rm -f $(PREFIX)/bin/$(DESTFILE)
	rm -rf $(DATAPATH)
	#rm -f $(MANPATH)/cheat.1
