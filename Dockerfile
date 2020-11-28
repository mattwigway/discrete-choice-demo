# have to use a docker file to get R 4.0
FROM rocker/rstudio:4.0.3

# install jupyter notebook
RUN pip install --no-cache-dir notebook==5.*

ARG NB_USER=tarheel
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

COPY . ${HOME}
USER root
RUN chown -R ${NB_UID} ${HOME}
USER ${NB_USER}

RUN R --no-save < install.R
