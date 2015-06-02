all:
	rsync -e ssh -avz ./ feamster@portal.cs.princeton.edu:public_html/
