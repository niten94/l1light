.POSIX:
DESTDIR =
PREFIX  = ~/.local
BINDIR  = $(PREFIX)/bin
DATADIR = $${XDG_DATA_HOME:-$$HOME/.local/share}
MANDIR  = $(DATADIR)/man

all: l1light.sh l1light.1

install: all
	mkdir -p $(DESTDIR)$(BINDIR) $(DESTDIR)$(MANDIR)/man1
	cp l1light.sh $(DESTDIR)$(BINDIR)/l1light
	gzip -c l1light.1 > $(DESTDIR)$(MANDIR)/man1/l1light.1.gz

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/l1light $(DESTDIR)$(MANDIR)/man1/l1light.1.gz
