FROM debian:trixie
COPY build.sh /build.sh
ENTRYPOINT ["bash", "/build.sh"]
