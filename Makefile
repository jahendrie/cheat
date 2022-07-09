################################################################################
#	Makefile for cheat.sh
#
#	Technically, no 'making' occurs, since it's just a shell script, but
#	let us not quibble over trivialities such as these.
################################################################################
PREFIX=/usr
SRC=src
SRCFILE=cheat.sh
DESTFILE=cheat
DOC=doc
DATA=data
MANPATH=$(PREFIX)/share/man/man1
MANFILE=cheat.1.gz
DATAPATH=$(PREFIX)/share/cheat
SHEETPATH=$(DATAPATH)/cheatsheets

install:
	install -D -m 0755 $(SRC)/$(SRCFILE) $(PREFIX)/bin/$(DESTFILE)
	mkdir -vp $(DATAPATH)
	cp -rv $(DATA) $(SHEETPATH)
	install -v -D -m 0644 LICENSE $(DATAPATH)/LICENSE
	install -v -D -m 0644 README $(DATAPATH)/README
	install -D -m 0644 $(DOC)/$(MANFILE) $(MANPATH)/$(MANFILE)

uninstall:
	rm -f $(PREFIX)/bin/$(DESTFILE)
	rm -rf $(DATAPATH)
	rm -f $(MANPATH)/$(MANFILE)
