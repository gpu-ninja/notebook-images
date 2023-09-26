FROM debian:bookworm
LABEL maintainer="damian@pecke.tt"

# Generic Linux tools.
RUN apt update \
  && apt install -y ca-certificates curl gnupg procps git fio

# Set up the Jupyter user (jovyan is the convention).
ENV NB_USER=jovyan \
  NB_UID=1000
ENV HOME=/home/${NB_USER} \
  SHELL=/bin/bash
RUN adduser --disabled-password --home "${HOME}" --shell=/bin/bash --uid=${NB_UID} "${NB_USER}"

# Node.js is required for JupyterLab extensions.
RUN mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
ARG NODE_VERSION=20
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
  && apt update \
  && apt install -y nodejs

ARG MINIFORGE_VERSION=23.3.1-1
ARG PYTHON_VERSION=3.11.5
ARG PIP_VERSION=23.2.1
ENV CONDA_DIR=/opt/conda PATH=/opt/conda/bin:$PATH
RUN curl -fsSL -o /tmp/mambaforge.sh https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Mambaforge-${MINIFORGE_VERSION}-Linux-$(uname -m).sh \
  && chmod +x /tmp/mambaforge.sh \
  && /tmp/mambaforge.sh -b -f -p "${CONDA_DIR}" \
  # Don't automatically update conda itself.
  && conda config --system --set auto_update_conda false \
  && conda install -y -q \
    python=${PYTHON_VERSION} \
    pip=${PIP_VERSION} \
  && conda clean -a -f -y \
  # Give the jupyter user the ability to manage python packages.
  && echo "export PATH=${CONDA_DIR}/bin:$PATH" >> "${HOME}/.bashrc" \
  && chown -R ${NB_USER}:users "${CONDA_DIR}" "${HOME}"

USER ${NB_USER}

ARG JUPYTERLAB_VERSION=4.0.6
RUN conda install -y -q \
    jupyterlab=${JUPYTERLAB_VERSION} \
  && conda clean -a -f -y

# Backup the user's home directory as we'll be bind mounting over it.
USER root
RUN tar -cf "/home/${NB_USER}.tar" -C "${HOME}" .

USER ${NB_USER}
WORKDIR ${HOME}

EXPOSE 8888/tcp

ENTRYPOINT ["/opt/conda/bin/jupyter", "lab", "--no-browser"]