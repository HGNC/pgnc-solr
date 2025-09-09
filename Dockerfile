FROM solr:8
LABEL maintainer="Kristian Gray <kag56@cam.ac.uk>"

USER solr

COPY --chown=solr:solr security/ /var/solr/security/
COPY --chown=solr:root cores /var/solr
RUN chmod +x /var/solr/security/docker-entrypoint.sh /var/solr/security/init-security.sh

USER solr

ENTRYPOINT ["/var/solr/security/docker-entrypoint.sh"]
CMD ["solr-fg"]