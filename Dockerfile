FROM node:14
WORKDIR /build/webs
COPY . ./
RUN  npm install && npm run build


FROM golang:alpine
WORKDIR /build/rttys
ADD https://github.com/zhaojh329/rttys/archive/refs/tags/v4.0.1.tar.gz ./
RUN tar -xvf v4.0.1.tar.gz -C /build/rttys && \
    cp -r rttys-4.0.1/* ./ && rm -rf v4.0.1.tar.gz rttys-v4.0.1
COPY --from=0 /build/webs/dist /build/rttys/ui/dist
RUN apk update && \
    apk add git gcc linux-pam-dev libc-dev && \
    go install -v github.com/rakyll/statik@latest && \
    statik -src=/build/rttys/ui/dist && \
    go build -ldflags "-w -s"


FROM alpine
WORKDIR /rttys
RUN apk update && \
    apk add --no-cache linux-pam-dev
COPY  --from=1 /build/rttys/rttys /rttys/rttys
ENTRYPOINT ["/rttys/rttys"]
