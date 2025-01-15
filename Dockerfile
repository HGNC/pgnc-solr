FROM solr:8
MAINTAINER Kristian Gray <kag56@cam.ac.uk>
COPY --chown=solr:root cores /var/solr