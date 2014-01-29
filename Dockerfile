FROM ubuntu
RUN apt-get update
RUN apt-get install -y libgmp3-dev libffi-dev
RUN cd /usr/lib/x86_64-linux-gnu ;  ln -s libffi.so.6 libffi.so.5