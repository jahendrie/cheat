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

install:
	install -D -g 0 -o 0 -m 0755 $(SRC)/$(SRCFILE) $(PREFIX)/bin/$(DESTFILE)
	install -v -D -g 0 -o 0 -m 0644 LICENSE $(DATAPATH)/LICENSE
	install -v -D -g 0 -o 0 -m 0644 README $(DATAPATH)/README
	#install -D -g 0 -o 0 -m 0644 $(DOC)/cheat.1 $(MANPATH)/cheat.1

uninstall:
	rm -f $(PREFIX)/bin/$(DESTFILE)
	rm -f $(DATAPATH)/LICENSE
	rm -f $(DATAPATH)/README
	rmdir $(DATAPATH)
	#rm -f $(MANPATH)/cheat.1
