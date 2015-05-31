all:
	rsync -e ssh -avz ./ portal.cs.princeton.edu:public_html/
