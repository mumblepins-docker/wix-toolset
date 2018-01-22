FROM circleci/openjdk:9-jdk

USER root

RUN set -ex; \
    dpkg --add-architecture i386 ;\
    wget -nc https://dl.winehq.org/wine-builds/Release.key ;\
    apt-key add Release.key ;\
    echo "deb https://dl.winehq.org/wine-builds/debian/ $(awk '{print $3}' /etc/apt/sources.list) main" >> /etc/apt/sources.list ;\
    apt-get update ;\
    apt-get install -y binutils cabextract p7zip unzip wget file ;\
    apt-get install -y --install-recommends winehq-stable 


RUN set -ex ;\
    curl -SL 'https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks' -o /usr/local/bin/winetricks; \
    chmod +x /usr/local/bin/winetricks


RUN useradd -d /home/wix -m -s /bin/bash wix
USER wix
ENV HOME /home/wix
ENV WINEPREFIX /home/wix/.wine
ENV WINEARCH win32

RUN set -ex ;\
    wine wineboot ;\
    xvfb-run winetricks --unattended dotnet40 corefonts 
    
    
WORKDIR /home/wix

RUN set -ex ;\
    wget -O wix-binaries.zip https://github.com/wixtoolset/wix3/releases/download/wix3111rtm/wix311-binaries.zip ;\
    unzip wix-binaries.zip ;\
    rm -rf wix-binaries.zip doc sdk

USER root
RUN set -ex; \
    for a in $(find /home/wix -maxdepth 1 -iname '*.exe' ); do \
        b=$(echo "$a" | sed -r 's|^.*/([^.]*).exe$|\1|'); \
        echo '#!/bin/bash' > "/usr/local/bin/$b"; \
        echo "wine  $a"'$@' >> "/usr/local/bin/$b"; \
        chmod +x "/usr/local/bin/$b" ;\
    done

RUN set -ex ;\
    cd /tmp ;\
    mkdir -p ivy ;\
    cd ivy ;\
    curl -sSL http://mirror.cc.columbia.edu/pub/software/apache//ant/ivy/2.4.0/apache-ivy-2.4.0-bin.tar.gz | tar xvz --strip-components=1 ;\
    cp ivy-*.jar $ANT_HOME/lib/ ;\
    cd .. ;\
    rm -rf ivy ;\
    cd $ANT_HOME ;\
    ant -f fetch.xml -Ddest=system ;\
    cd /home/wix


USER wix

ENTRYPOINT ["/bin/bash"]
    
