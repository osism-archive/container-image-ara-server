ARG VERSION

FROM pypy:3.7-slim as builder

COPY files/requirements.txt /requirements.txt

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      build-essential \
      gcc \
      libffi-dev \
      libmariadb-dev \
      libssl-dev \
      libyaml-dev \
    && mkdir /wheels \
    && python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip wheel --no-cache-dir --wheel-dir=/wheels -r /requirements.txt \
    && if [ $VERSION != "latest" ]; then python3 -m pip wheel--no-cache-dir --wheel-dir=/wheels "ara[server]==$VERSION"; else python3 -m pip wheel --wheel-dir=/wheels --no-cache-dir "ara[server]"; fi

FROM pypy:3.7-slim

ENV TZ=UTC

ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.9.0/wait /wait

COPY --from=builder /wheels /wheels
COPY files/requirements.txt /requirements.txt
COPY files/run.sh /run.sh

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      curl \
      libmariadb3 \
    && python3 -m pip --no-cache-dir install -U 'pip==21.0.1' \
    && python3 -m pip install --no-index --find-links=/wheels -r /requirements.txt \
    && python3 -m pip install --no-index --find-links=/wheels ara[server] \
    && useradd ara-server \
    && chmod +x /wait \
    && rm -rf /var/lib/apt/lists/* /wheels /requirements.txt \

USER ara-server
WORKDIR /home/ara-server

EXPOSE 8000

CMD ["sh", "-c", "/wait && /run.sh"]
HEALTHCHECK CMD curl --fail http://localhost:8000 || exit 1

LABEL "org.opencontainers.image.documentation"="https://docs.osism.tech" \
      "org.opencontainers.image.licenses"="ASL 2.0" \
      "org.opencontainers.image.source"="https://github.com/osism/container-image-ara-server" \
      "org.opencontainers.image.url"="https://www.osism.tech" \
      "org.opencontainers.image.vendor"="OSISM GmbH"
