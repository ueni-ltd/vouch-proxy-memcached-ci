# quay.io/vouch/vouch-proxy
# https://github.com/vouch/vouch-proxy
FROM golang:1.19 AS builder

ARG UID=999
ARG GID=999
LABEL maintainer="vouch@bnf.net"

RUN mkdir -p ${GOPATH}/src/github.com/vouch/vouch-proxy
WORKDIR ${GOPATH}/src/github.com/vouch/vouch-proxy

RUN groupadd -g $GID vouch \
    && useradd --system vouch --uid=$UID --gid=$GID

COPY . .


RUN ./do.sh goget
RUN ./do.sh gobuildstatic # see `do.sh` for vouch-proxy build details
RUN ./do.sh install

FROM scratch
LABEL maintainer="vouch@bnf.net"
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder /go/bin/vouch-proxy /vouch-proxy

USER vouch

EXPOSE 9090
ENTRYPOINT ["/vouch-proxy"]
HEALTHCHECK --interval=1m --timeout=5s CMD [ "/vouch-proxy", "-healthcheck" ]
