FROM solr:9.9.0
LABEL maintainer="Kristian Gray <kag56@cam.ac.uk>"

# Add Jakarta Activation API so Jersey can register DataSource MessageBodyWriter
USER root
RUN set -eux; \
    mkdir -p /opt/solr/server/lib/ext; \
    curl -fsSL -o /opt/solr/server/lib/ext/jakarta.activation-api-2.1.3.jar \
    https://repo1.maven.org/maven2/jakarta/activation/jakarta.activation-api/2.1.3/jakarta.activation-api-2.1.3.jar; \
    chown -R solr:solr /opt/solr/server/lib/ext
USER solr