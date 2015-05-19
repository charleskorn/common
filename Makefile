.PHONY: all build client static dist test clean

# If you can use Docker without being root, you can `make SUDO= <target>`
SUDO=sudo

DOCKERHUB_USER=weaveworks
APP_EXE=app/app
PROBE_EXE=probe/probe
FIXPROBE_EXE=experimental/fixprobe/fixprobe
SCOPE_IMAGE=$(DOCKERHUB_USER)/scope
SCOPE_EXPORT=scope.tar

all: $(SCOPE_EXPORT)
dist: client static $(APP_EXE) $(PROBE_EXE)

client:
	cd client && make build && rm -f dist/.htaccess

app/static.go:
	go get github.com/mjibson/esc
	esc -o app/static.go -prefix client/dist client/dist

test: $(APP_EXE) $(FIXPROBE_EXE)
	# app and fixprobe needed for integration tests
	go test ./...

$(APP_EXE): app/*.go app/static.go report/*.go xfer/*.go
$(PROBE_EXE): probe/*.go report/*.go xfer/*.go

$(APP_EXE) $(PROBE_EXE):
	go get -tags netgo ./$(@D)
	go build -o $@ ./$(@D)

$(FIXPROBE_EXE):
	cd experimental/fixprobe && go build

$(SCOPE_EXPORT):  $(APP_EXE) $(PROBE_EXE) docker/Dockerfile docker/entrypoint.sh
	cp $(APP_EXE) $(PROBE_EXE) docker/
	$(SUDO) docker build -t $(SCOPE_IMAGE) docker/
	$(SUDO) docker save $(SCOPE_IMAGE):latest > $@

clean:
	go clean ./...
	rm -f $(SCOPE_EXPORT) app/static.go
