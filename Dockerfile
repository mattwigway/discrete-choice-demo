## Use a tag instead of "latest" for reproducibility
FROM rocker/rstudio:4.0.3

ENV NB_USER=rstudio
ENV NB_UID=1000

## Copies your repo files into the Docker Container
USER root
COPY . ${HOME}
## Enable this to copy files from the binder subdirectory
## to the home, overriding any existing files.
## Useful to create a setup on binder that is different from a
## clone of your repository
## COPY binder ${HOME}
RUN chown -R ${NB_USER} ${HOME}

RUN /rocker_scripts/install_python.sh
RUN /rocker_scripts/install_binder.sh

## Become normal user again
USER ${NB_USER}

## Run an install.R script, if it exists.
RUN if [ -f install.R ]; then R --quiet -f install.R; fi

CMD jupyter notebook --ip 0.0.0.0

USER ${NB_USER}

WORKDIR /home/${NB_USER}
