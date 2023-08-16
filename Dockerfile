FROM debian:bookworm
LABEL maintainer="damian@pecke.tt"

# Set up the Jupyter user (jovyan is the convention).
ENV NB_USER=jovyan \
  NB_UID=1000
ENV HOME=/home/${NB_USER}
RUN adduser --disabled-password --home "${HOME}" --shell=/bin/bash --uid=${NB_UID} "${NB_USER}"

# Node.js is required for JupyterLab extensions.
ARG NODE_VERSION=20
ADD --chmod=0755 https://deb.nodesource.com/setup_${NODE_VERSION}.x /tmp/nodesource_setup.sh
RUN /tmp/nodesource_setup.sh \
 && apt install -y nodejs

ARG MINIFORGE_VERSION=23.1.0-4
ARG PYTHON_VERSION=3.11.4
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

ARG JUPYTERLAB_VERSION=4.0.5
RUN conda install -y -q \
    jupyterlab=${JUPYTERLAB_VERSION} \
  && conda clean -a -f -y

WORKDIR ${HOME}

EXPOSE 8888/tcp

ENTRYPOINT ["/opt/conda/bin/jupyter", "lab", "--no-browser"]