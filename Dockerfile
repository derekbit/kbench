FROM golang:1.23-alpine AS base

ARG TARGETARCH

RUN apk -U add bash git gcc musl-dev vim less file curl wget ca-certificates

ENV ARCH=${TARGETARCH}

WORKDIR /go/src/github.com/longhorn/kbench
COPY . .

FROM base AS build
RUN ./scripts/build

FROM base AS validate
RUN ./scripts/validate && touch /validate.done

FROM scratch AS build-artifacts
COPY --from=build /go/src/github.com/longhorn/kbench/bin/ /bin/

FROM scratch AS ci-artifacts
COPY --from=validate /validate.done /validate.done
COPY --from=build /go/src/github.com/longhorn/kbench/bin/ /bin/
