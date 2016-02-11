FROM insighttoolkit/simpleitk-notebooks:latest
MAINTAINER Matt McCormick <matt.mccormick@kitware.com>

USER root
RUN curl https://get.docker.com/builds/Linux/x86_64/docker-1.9.1 -o /usr/bin/docker && \
  chmod +x /usr/bin/docker

ADD busybox.dockerarchive.tar /home/jovyan/notebooks/
ADD *.ipynb /home/jovyan/notebooks/

USER jovyan
