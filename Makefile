all: uchicago

princeton:
	rsync -e ssh -avz --exclude=.git ./ feamster@portal.cs.princeton.edu:public_html/

uchicago:
	rsync -e ssh -avz --exclude=.git ./ feamster@linux.cs.uchicago.edu:html/
