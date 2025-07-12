VERSION ?= 1.0.8

.PHONY: release clean

release:
	./release.sh $(VERSION)

clean:
	rm -rf build icon_logo-*.tar.gz icon_logo.rb
