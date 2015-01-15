libs=src/perllib/.
cli=src/cli/.
target=/usr/local/there
targetlibs=$(target)/perllib
targetcli=$(target)/bin
targetbin=/usr/local/bin
links=there thereto
rsync=rsync -rlt -v -e ssh --omit-dir-times
wrapname=there-wrapper

.dummy:

clean:
	rm -f $(cli)/$(wrapname)

test:
	prove t/*.t

install: wrapper Makefile .dummy
	mkdir -p $(target)
	$(rsync) $(libs) $(targetlibs)
	$(rsync) $(cli)  $(targetcli)
	for x in $(links); do ln -fs $(targetcli)/$(wrapname) $(targetbin)/$$x; done

uninstall: 
	rm -r $(target)
	for x in $(links); do rm $(targetbin)/$$x; done

$(cli)/$(wrapname): Makefile
	echo "#!/bin/sh" > $@
	echo umask 0 >> $@
	echo 'exec perl -I$(targetlibs) -wT -Mstrict $(targetcli)/$$(basename $$0) $$@' >> $@
	chmod a+x $@

wrapper: $(cli)/$(wrapname)
