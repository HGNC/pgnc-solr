FROM solr:8
MAINTAINER Kristian Gray <kag56@cam.ac.uk>

# Copy cores as before
COPY --chown=solr:root cores /var/solr

# Copy security configuration
COPY --chown=solr:solr security/ /var/solr/security/
RUN chmod +x /var/solr/security/init-security.sh
RUN chmod +x /var/solr/security/docker-entrypoint.sh
RUN cp /var/solr/security/security.json /var/solr/data/security.json
RUN chown solr:solr /var/solr/data/security.json
RUN chmod 600 /var/solr/data/security.json

ENTRYPOINT ["/var/solr/security/docker-entrypoint.sh"]
CMD ["solr-foreground"]