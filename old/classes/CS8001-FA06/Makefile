PUBHOST=rigel.cc.gatech.edu
PUBDIR=www/classes/CS8001-FA06/
SRCS = index.html style.css

all: local

publish: index.html
	rsync -e ssh -avz ./ $(PUBHOST):$(PUBDIR)

local: $(SRCS)

index.html: index.srhtml FORCE
	./bp.rb


FORCE:
