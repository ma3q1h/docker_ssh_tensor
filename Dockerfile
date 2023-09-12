ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG USER
ARG UID
ARG GID
ARG USER_PASSWD
ARG ROOT_PASSWD
ARG PYTHON_VERSION
ARG CONTAINER_PORT
#ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS=yes

USER root

#tz
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
RUN rm -f /etc/apt/sources.list.d/archive_uri-*
RUN apt-get update

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -yqq --no-install-recommends tzdata
ENV TZ=Asia/Tokyo

#aptget install
RUN apt-get update && apt-get install -yqq --no-install-recommends \
    language-pack-ja-base \
    locales \
    init \
    systemd \
    git \
    vim \
    less \
    curl \
    sudo \
    tree \
    make \
    cmake \
    g++ \
    gcc \
    ffmpeg \
    bash-completion \
    iproute2 \
    ssh \
    openssh-server \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#add sudo user/root
RUN echo "root:${ROOT_PASSWD}" | chpasswd
RUN groupadd -g "${GID}" "${USER}"
RUN useradd -m -d /home/${USER} -s /bin/bash -f '-1' -u ${UID} -g ${GID} ${USER} && gpasswd -a ${USER} sudo
RUN echo "${USER}:${USER_PASSWD}" | chpasswd
RUN echo "%${USER}    ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers 
RUN echo "%${USER}    ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${USER}
RUN chmod 0440 /etc/sudoers.d/${USER}
RUN chsh -s /bin/bash ${USER}
ENV PATH /home/${USER}/.local/bin:$PATH

#locales
RUN locale-gen ja_JP.UTF-8
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
RUN echo "export LANG=ja_JP.UTF-8" >> /home/${USER}/.bashrc
RUN sed '/LANG/s/^/# /g' /etc/ssh/ssh_config
RUN . /home/${USER}/.bashrc

#set src & work dir
RUN mkdir -p /home/${USER}/src
COPY ./src /home/${USER}/src
RUN chown -R ${USER}:${USER} /home/${USER}/src
RUN chmod -R 777 /home/${USER}/src/
RUN mkdir -p /home/${USER}/work
RUN chown -R ${USER}:${USER} /home/${USER}/work

#install python_builders
RUN apt-get update && apt-get install -y --no-install-recommends build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev && apt-get autoremove -yqq --purge && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN rm -f /etc/apt/sources.list.d/archive_uri-*
RUN apt-get update && apt-get install -y --no-install-recommends python3-pip && apt-get autoremove -yqq --purge && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN pip install -U pip wheel setuptools
#python-is-python3

USER ${USER}
WORKDIR /home/${USER}

#set cdls(cd + ls -a)
RUN echo -e "\\ncdls()\\n{\\n\\tcd \"\$@\" && ls -a --color=auto\\n}\\nalias cd=\"cdls\"" >> /home/${USER}/.bashrc
RUN . /home/${USER}/.bashrc

#install pyenv
ENV PYENV_ROOT="/home/${USER}/.pyenv" \
    PATH="/home/${USER}/.pyenv/bin:/home/${USER}/.pyenv/shims:$PATH"
RUN curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

#install python & run
RUN pyenv install ${PYTHON_VERSION} \
    && pyenv global ${PYTHON_VERSION} \
    && pip install -U pip wheel setuptools

#install pip library
RUN pip install --user -r /home/${USER}/src/requirements.txt
RUN ipython kernel install --user --name=docker --display-name=docker

#ssh
USER root
RUN mkdir /var/run/sshd
RUN sed -ri 's/^#?Port\s+.*/Port 22/' /etc/ssh/sshd_config
RUN sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -ri 's/^#?PubkeyAuthentication\s+.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
RUN sed -ri 's/^#?PasswordAuthentication\s+.*/PasswordAuthentication no/' /etc/ssh/sshd_config
RUN sed -ri 's/^#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config
#RUN sed -i 's/^\(UsePAM yes\)/# \1/' /etc/ssh/sshd_config;
#RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd
#ENV NOTVISIBLE "in users profile"
#RUN echo "export VISIBLE=now" >> /etc/profile
RUN mkdir /home/${USER}/.ssh
COPY --chown=${USER}:{USER} id_rsa.pub /home/${USER}/.ssh/authorized_keys

# make bash_profile for ssh
RUN echo "if [ -f ~/.bashrc ]; then  . ~/.bashrc;  fi" >>  /home/${USER}/.bash_profile
RUN echo "PATH=${PATH}:/usr/local/spark/bin" >> /home/${USER}/.bashrc
#RUN service ssh start

USER ${USER}
#RUN sudo systemctl start ssh
WORKDIR /home/${USER}
EXPOSE ${CONTAINER_PORT}
ENTRYPOINT sudo service ssh start && bash