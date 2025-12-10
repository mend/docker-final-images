FROM mend/base-repo-scanner:25.11.1

ARG USER_NAME=wss-scanner
ARG USER_ID=1000
ARG USER_HOME=/home/${USER_NAME}
ARG APT_HTTP_PROXY

ENV BASH_ENV=/usr/local/etc/env
SHELL ["/bin/bash", "-c"]

# START OF FINAL IMAGE

## Uncomment the below to enable Dynamic package manager install for selected package managers
##
# COPY --from=containerbase/runinstall:20240327 /home/ubuntu/bin/runinstall ${USER_HOME}/.local/bin/runinstall
# RUN ln -s ${USER_HOME}/.local/bin/runinstall ${USER_HOME}/.local/bin/mvn
# RUN ln -s ${USER_HOME}/.local/bin/runinstall ${USER_HOME}/.local/bin/pipenv

# Download the pre-scan builder and set it in $PATH, can be replaced by:
#--build-arg $PSB_URL=URL
RUN echo "Downloading PSB version 8.1"
ARG PSB_URL=https://downloads.mend.io/production/sca/pre-scan-builder/25.8.1/linux_amd64/psb
RUN curl $PSB_URL --create-dirs -o /psb/bin/psb && chmod 0775 -R /psb
# ┌────────────┬────────────┬───────────────────────────────────────────────────────────────────┐
# │ Severity   │ Count      │ CVEs                                                              │
# ├────────────┼────────────┼───────────────────────────────────────────────────────────────────┤
# │ Critical   │ 1          │ CVE-2025-22871                                                    │
# ├────────────┼────────────┼───────────────────────────────────────────────────────────────────┤
# │ High       │ 6          │ CVE-2025-58186, CVE-2024-34156, CVE-2025-47907, CVE-2025-58188    │
# │            │            │ CVE-2025-58183, CVE-2025-58187                                    │
# └────────────┴────────────┴───────────────────────────────────────────────────────────────────┘
ENV PATH=$PATH:/psb/bin/

# Download the mend sca tool
#--build-arg $SCA_TOOL_URL=URL
USER 0
ARG SCA_TOOL_URL=https://downloads.mend.io/production/sca/sca-wrapper/25.10.3.2/linux_amd64/sca-wrapper
RUN echo "Downloading Mend SCA tool [$SCA_TOOL_URL]"
RUN curl $SCA_TOOL_URL --create-dirs -o /sca-wrapper/bin/sca-wrapper && chmod 0777 -R /sca-wrapper
ENV MEND_SCA_BIN_DIR=/sca-wrapper/bin
ENV PATH=$PATH:$MEND_SCA_BIN_DIR
ENV MEND_SCA_SCAN_PRINT_ENGINE_LOGS=true
USER ${USER_ID}
RUN sca_tool_version="$(sca-wrapper version)" && echo "Mend-SCA-Tool Version:" $sca_tool_version
RUN sca-wrapper init
USER 0
RUN chmod 0777 -R /sca-wrapper
# ┌────────────┬────────────┬───────────────────────────────────────────────────────────────────┐
# │ Severity   │ Count      │ CVEs                                                              │
# ├────────────┼────────────┼───────────────────────────────────────────────────────────────────┤
# │ Critical   │ 4          │ CVE-2025-22871, CVE-2025-22871, CVE-2025-22871, CVE-2025-22871    │
# ├────────────┼────────────┼───────────────────────────────────────────────────────────────────┤
# │ High       │ 28         │ CVE-2025-30204, CVE-2025-58188, CVE-2025-22869, CVE-2024-7254     │
# │            │            │ CVE-2025-58187, CVE-2025-58183, CVE-2025-58188, CVE-2025-47907    │
# │            │            │ CVE-2025-22874, CVE-2025-58183, CVE-2025-47907, CVE-2025-47907    │
# │            │            │ CVE-2025-58187, CVE-2025-58187, CVE-2025-58187, CVE-2025-58188    │
# │            │            │ CVE-2025-58183, CVE-2025-58188, CVE-2025-58183, CVE-2025-58186    │
# │            │            │ CVE-2025-58186, CVE-2022-3510, CVE-2022-3509, CVE-2025-58186      │
# │            │            │ CVE-2022-3171, CVE-2025-58186, CVE-2025-47907, CVE-2024-34156     │
# └────────────┴────────────┴───────────────────────────────────────────────────────────────────┘

# Download the SAST CLI and set it in $PATH, can be replaced by:
#--build-arg SASTCLI=URL
RUN echo "Downloading Mend Unified CLI wrapper"
ARG SASTCLI=https://downloads.mend.io/cli/linux_amd64/mend
RUN curl $SASTCLI --create-dirs -o /sast/bin/mend && chmod 0775 /sast/bin/mend
ENV PATH=$PATH:/sast/bin

### copy folder
COPY docker-image-scanner/ /
# ┌────────────┬────────────┬────────────────────────────────────────────────────────────────┐
# │ Severity   │ Count      │ CVEs                                                           │
# ├────────────┼────────────┼────────────────────────────────────────────────────────────────┤
# │ High       │ 7          │ CVE-2025-58056, CVE-2023-3894, CVE-2022-3510, CVE-2022-3509    │
# │            │            │ CVE-2022-3171, CVE-2024-7254, CVE-2025-58057                   │
# └────────────┴────────────┴────────────────────────────────────────────────────────────────┘


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
