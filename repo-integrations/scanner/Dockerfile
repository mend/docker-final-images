FROM mend/base-repo-scanner:24.6.1

## Uncomment the below to enable Dynamic package manager install for selected package managers
##
# COPY --from=containerbase/runinstall:20240327 /home/ubuntu/bin/runinstall ${USER_HOME}/.local/bin/runinstall
# RUN ln -s ${USER_HOME}/.local/bin/runinstall ${USER_HOME}/.local/bin/mvn
# RUN ln -s ${USER_HOME}/.local/bin/runinstall ${USER_HOME}/.local/bin/pipenv
# RUN ln -s ${USER_HOME}/.local/bin/runinstall ${USER_HOME}/.local/bin/poetry

# Download the pre-scan builder and set it in $PATH, can be replaced by:
#--build-arg $PSB_URL=URL
RUN echo "Downloading PSB version 24.5.1"
ARG PSB_URL=https://wss-public.s3.amazonaws.com/pre-scan-builder/production/24.5.1/linux_amd64/psb
RUN curl $PSB_URL --create-dirs -o /psb/bin/psb && chmod 0775 -R /psb
ENV PATH=$PATH:/psb/bin/

# Download the SAST CLI and set it in $PATH, can be replaced by:
#--build-arg SASTCLI=URL
RUN echo "Downloading SAST CLI version 23.11.2.2"
ARG SASTCLI=https://downloads-sast.whitesourcesoftware.com/sast-cli/linux/wscli
RUN curl $SASTCLI --create-dirs -o /sast/bin/wscli && chmod 0775 /sast/bin/wscli
ENV PATH=$PATH:/sast/bin


### copy folder
COPY docker-image/ /

RUN chmod 755 /start.sh
RUN chgrp -R 0 ${USER_HOME} && chmod -R g=u ${USER_HOME}

ENV SCM_SCANNER_HOME=/etc/usr/local/whitesource/scm-scanner
RUN chmod -R ugo+rw ${SCM_SCANNER_HOME}
ENV LOG4J_FORMAT_MSG_NO_LOOKUPS=true
### Switch User ###
ENV HOME ${USER_HOME}
WORKDIR ${USER_HOME}
USER ${USER_NAME}
ARG JAVA_OPTS
ENV JAVA_OPTS=${JAVA_OPTS}
ENV JDK_JAVA_OPTIONS "--add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/sun.reflect.generics.reflectiveObjects=ALL-UNNAMED"

EXPOSE 9393

ENTRYPOINT ["docker-entrypoint.sh"]
# Mend traceability labels
LABEL io.mend.image.dockerfile.path=integration-new/github-scanner-parent/scm-packaging/src/assembly-staging/docker/Dockerfile
LABEL org.opencontainers.image.source=https://github.com/whitesource/github-scanner

CMD ["/start.sh"]