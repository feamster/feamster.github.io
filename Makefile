all: uchicago
	rsync -e ssh -avz ./ feamster@portal.cs.princeton.edu:public_html/

uchicago:
	rsync -e ssh -avz ./ feamster@linux.cs.uchicago.edu:html/
