FROM debian:sid
COPY build.sh /build.sh
ENTRYPOINT ["bash", "/build.sh"]
