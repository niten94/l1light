.POSIX:
DESTDIR =
PREFIX  = ~/.local
BINDIR  = $(PREFIX)/bin
DATADIR = $${XDG_DATA_HOME:-$$HOME/.local/share}
MANDIR  = $(DATADIR)/man

all: l1light.sh l1light.1

install: all
	mkdir -p $(BINDIR) $(MANDIR)/man1
	cp l1light.sh $(BINDIR)/l1light
	gzip -c l1light.1 > $(MANDIR)/man1/l1light.1.gz

uninstall:
	rm -f $(BINDIR)/l1light $(MANDIR)/man1/l1light.1.gz
