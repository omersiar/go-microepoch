# STEP 1 build executable binary

# golang alpine 1.12
FROM golang@sha256:8cc1c0f534c0fef088f8fe09edc404f6ff4f729745b85deae5510bfd4c157fb2 as builder

# Install git, Git is required for fetching the dependencies.
RUN apk update && apk add --no-cache git 

# Create appuser
RUN adduser -D -g '' appuser

WORKDIR $GOPATH/src/mypackage/epoch/
COPY . .

# Fetch dependencies.
RUN go get -d -v

# Build the binary
RUN GITREV=$(git rev-parse --short HEAD) && \
 CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s -X main.Version=$GITREV" -a -installsuffix cgo -o /go/bin/epoch .

##
# STEP 2 build a small image

FROM scratch

# Import from builder.
COPY --from=builder /etc/passwd /etc/passwd

# Copy our static executable
COPY --from=builder /go/bin/epoch /go/bin/epoch

# Use an unprivileged user.
USER appuser

# Run the hello binary.
ENTRYPOINT ["/go/bin/epoch"]

EXPOSE 8080
