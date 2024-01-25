FROM ubuntu:22.04
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    LANG=C.UTF-8 \
    SHELL=/bin/bash \
    PS1="\u@\h:\w \$ " \
    DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# Combine installation of packages and clean up in one RUN command
RUN apt-get update && \
    apt-get install --no-install-recommends -y apt-utils tzdata locales dnsutils iproute2 openssh-server sudo iftop nano vim wget supervisor screen libpcap-dev upx cron jq xterm git openssl curl iputils-ping python3 python3-tk python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV TERM xterm-256color

# Combine wget, gzip, mv, chmod, and rm commands
RUN wget -t 2 -T 10 -N --no-check-certificate https://github.com/MetaCubeX/Clash.Meta/releases/download/v1.15.0/clash.meta-linux-amd64-v1.15.0.gz && \
    gzip -d clash.meta-linux-amd64-v1.15.0.gz && \
    mv clash.meta-linux-amd64-v1.15.0 /bin/hhhh && \
    chmod +x /bin/hhhh && \
    upx -9 /bin/hhhh && \
    rm -rf clash.meta-linux-amd64-v1.15.0.gz

# Combine installation of nodejs and pm2
RUN apt-get update && \
    apt-get install --no-install-recommends -y ca-certificates curl gnupg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install --no-install-recommends -y nodejs && \
    npm install -g pm2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# FROM python:3.9

# WORKDIR /code

COPY requirements.txt requirements.txt

RUN pip install --no-cache-dir --upgrade -r requirements.txt

# COPY . .

EXPOSE 7860

# CMD ["shiny", "run", "app.py", "--host", "0.0.0.0", "--port", "7860"]
# Combine user creation, password setting, and SSH configuration
RUN useradd -m -s /bin/bash -u 1000 ubuntu && \
    echo 'ubuntu:password' | chpasswd && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

COPY . /home/ubuntu
COPY config.yaml /home/ubuntu/.config/clash/config.yaml

RUN chmod +x /home/ubuntu/*.sh &&\
    chown -R ubuntu:ubuntu / 2>/dev/null || true

USER ubuntu
WORKDIR /home/ubuntu

# Combine wget, chmod, and rm commands
RUN chmod +x /home/ubuntu/fofa-asn &&\
    chmod +x /home/ubuntu/asn.sh

CMD pm2-runtime start /home/ubuntu/ecosystem.config.js