FROM ghcr.io/inspire-mif/helpdesk-validator/inspire-validator:2024.3
LABEL description="Customized version of INSPIRE validator. Fixes hardcoded domain references and kubernetes/WSL problems where apache2 and squid fail to start"
# LABEL version="0.1"
# LABEL maintainer="Someone <someone@somewhere.org>"
# LABEL org.opencontainers.image.authors="Someone <someone@somewhere.org>"

# Jetty port
EXPOSE 8080/tcp
# Apache "new UI" port
EXPOSE 8090/tcp

# Allows apache2 and squid to start without having hostname
# Required for running on local WSL/container app in Azure
# https://github.com/INSPIRE-MIF/helpdesk-validator/issues/1107
# Also see: https://github.com/INSPIRE-MIF/helpdesk-validator/issues/1081#issuecomment-2205423986
RUN echo 'rc_need="!dev !net"' >> /etc/rc.conf

# Config domain where the service runs
# - empty string means current domain
# - JRC defaults to http://localhost:8090
# Affects:
#  - /etf/validator/js/config.js 
#  - /etf/config/etf-config.properties
ENV SERVICE_DOMAIN_OVERRIDE ""

# change /docker-entrypoint.sh file by injecting a sed command to replace localhost reference under /etf/validator/js/config.js.
# The sed change needs to be done in docker-entrypoint.sh as the sh-file unzips the files to apache docs folder ("/etf/") WHEN RUN, not when built
# Inject the sed command to the line with "# Download Webapp" as that is after the unzip ui.zip command
# replace http://localhost:8090 -> '' in /etf/validator/js/config.js so XHRs call whatever domain this is hosted on
# Fiddly: assumes there is a line "# Download Webapp" in the docker-entrypoint.sh
# https://github.com/INSPIRE-MIF/helpdesk-validator/issues/1051
RUN sed -i "s|# Download Webapp|sed -i 's}http://localhost:8090}'\"\$SERVICE_DOMAIN_OVERRIDE\"'}g' /etf/validator/js/config.js \n\n # Download Webapp|g" /docker-entrypoint.sh

# Remove debug mode from Jetty
RUN sed -i "s| -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=1044||g" /docker-entrypoint.sh
# The row that is modified is expected to be:
#JAVA_OPTIONS="-server $xms_xmx $javaHttpProxyOpts $javaHttpsProxyOpts -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=1044"

# Inject the config properties file. Looks like if we just add it to the path the webapp searchs for it we can inject a modified version.
COPY etf-config.properties /etf/config/

# Modify the base URL which points to the deployed web application.
# The URL is used to reference this ETF instance from the Test Reports.
# Example: http://yourserver/etf-webapp
#etf.webapp.base.url = http://localhost:8090/validator
RUN sed -i "s|http://localhost:8090|$SERVICE_DOMAIN_OVERRIDE|g" /etf/config/etf-config.properties

# Add a dummy index page to guide users to the /validator path
COPY index.html /var/lib/jetty/webapps/ROOT/
