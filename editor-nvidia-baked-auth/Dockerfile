# Install requirements for self-authentication
ARG geckoVersion="0.33.0"
ARG geckoUrl="https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz"

RUN sudo apt-get update && \
	sudo apt-get install -y python3-pip && \
	git clone https://github.com/cloudymax/unity-self-auth.git && \
	pip3 install selenium && \
    	sudo wget $geckoUrl && \
    	sudo tar xvfz geckodriver-v"$geckoVersion"-linux64.tar.gz && \
    	sudo rm geckodriver-v"$geckoVersion"-linux64.tar.gz && \
   	sudo mv geckodriver ~/.local/bin && \
	pip3 install -r unity-self-auth/requirements.txt

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
