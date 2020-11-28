# have to use a docker file to get R 4.0
FROM rocker/binder:4.0.3

COPY . ${HOME}
USER root
RUN chown -R ${NB_UID} ${HOME}
USER ${NB_USER}

RUN R --no-save < install.R
