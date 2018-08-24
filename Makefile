EDITOR=vim

include /etc/os-release
export TABLEAU_VERSION=2018-2-0
#TARGET_OS=ubuntu
TARGET_OS=centos

all: download install-prerequisites regconfig build

clean:
	sudo rm -rf data/ run/ etc/ log/
	sudo mkdir -p etc/opt/ etc/systemd/system
	sudo mkdir -p etc/systemd/system/multi-user.target.wants 
	sudo chmod 777 data/. run/. etc/. log/. etc/opt/. etc/systemd/system/. etc/systemd/system/multi-user.target.wants/.
	sudo ln -s /lib/systemd/system/multi-user.target etc/systemd/system/default.target
	

download:
ifeq ($(TARGET_OS),ubuntu)
	@echo downloading packages for Tableau ${TABLEAU_VERSION} for ${TARGET_OS}
	@mkdir -p download
	@wget -q -P download/ -c https://downloads.tableau.com/esdalt/${TABLEAU_VERSION}/tableau-tabcmd-${TABLEAU_VERSION}_all.deb
	@wget -q -P download/ -c https://downloads.tableau.com/esdalt/${TABLEAU_VERSION}/tableau-server-${TABLEAU_VERSION}_amd64.deb
endif
ifeq ($(TARGET_OS),centos) 
	@echo downloading packages for Tableau ${TABLEAU_VERSION} for ${TARGET_OS}
	@mkdir -p download
	@wget -q -P download/ -c https://downloads.tableau.com/esdalt/`echo ${TABLEAU_VERSION} | sed 's/-/\./g'`/tableau-server-${TABLEAU_VERSION}.x86_64.rpm
	@wget -q -P download/ -c https://downloads.tableau.com/esdalt/`echo ${TABLEAU_VERSION} | sed 's/-/\./g'`/tableau-tabcmd-${TABLEAU_VERSION}.noarch.rpm
endif

install-prerequisites:
ifeq ("$(wildcard /usr/bin/docker)", "")
        @echo install docker-ce, still to be tested
        sudo apt-get update
        sudo apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common

        curl -fsSL https://download.docker.com/linux/${ID}/gpg | sudo apt-key add -
        sudo add-apt-repository \
                "deb https://download.docker.com/linux/ubuntu \
                `lsb_release -cs` \
                stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce
        sudo curl -L https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
endif

network: 
	@docker network create latelier 2> /dev/null; true

build:
	docker-compose -f docker-compose-${TARGET_OS}.yml --verbose build 

init:
	docker exec -it tableau-server /opt/tableau/docker_build/tableau-init-configure.sh

status:
	docker exec -it tableau-server /opt/tableau/docker_build/tableau-status.sh

up: network
	docker-compose -f docker-compose-${TARGET_OS}.yml up -d

down:
	docker exec -it tableau-server /opt/tableau/docker_build/tableau-stop.sh
	docker-compose -f docker-compose-${TARGET_OS}.yml down

restart: down up

config/registration_file.json: 
	cp config/registration_file.json.templ config/registration_file.json
	$(EDITOR) config/registration_file.json

regconfig: config/registration_file.json


