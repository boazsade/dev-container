FROM ubuntu:latest

RUN apt-get -y update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata
ENV LANG en_US.utf8

RUN apt-get install -y build-essential \
    cmake ninja-build vim \
    clang-tidy git wget

RUN apt install -y python3-pip

RUN mkdir -p /workspace/conan 
ENV CONAN_HOME=/workspace/conan

RUN wget https://github.com/conan-io/conan/releases/download/2.9.1/conan-2.9.1-amd64.deb && \
	dpkg -i conan-2.9.1-amd64.deb && \
	rm -rf conan-2.9.1-amd64.deb


RUN conan profile detect --force && \
	grep -v compiler.cppst $CONAN_HOME/profiles/default > $CONAN_HOME/profiles/default.tmp && \
	echo compiler.cppstd=20 >> $CONAN_HOME/profiles/default.tmp && \
 	cp $CONAN_HOME/profiles/default.tmp $CONAN_HOME/profiles/default && \
	rm -f $CONAN_HOME/profiles/default.tmp && \
	chmod -R 0777 /workspace/conan

