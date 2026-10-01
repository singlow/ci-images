FROM eclipse-temurin:11.0.18_10-jdk-jammy

LABEL org.opencontainers.image.source=https://github.com/SSLcom/ci-images

ENV USERNAME=""
ENV PASSWORD=""
ENV CREDENTIAL_ID=""
ENV TOTP_SECRET=""
ENV CODE_SIGN_TOOL_PATH=/codesign
ENV ENVIRONMENT_NAME=PROD
ENV JVM_OPTS="-Xms512m -Xmx2048m"

# Install Packages
RUN apt update && apt install -y unzip vim wget curl

# Add CodeSignTool.
# sha256 of the v1.3.1 release zip. Update this when the version changes.
RUN curl -fsSL -o /tmp/CodeSignTool-v1.3.1.zip \
      "https://github.com/SSLcom/CodeSignTool/releases/download/v1.3.1/CodeSignTool-v1.3.1.zip" \
    && echo "83d72ca2f0cf9a61ec7f2b0470e91abfdb5999392170097f0f4d81cbea4a5458  /tmp/CodeSignTool-v1.3.1.zip" | sha256sum -c -

RUN mkdir -p "/codesign" && unzip "/tmp/CodeSignTool-v1.3.1.zip" -d "/codesign" && \
    chmod +x "/codesign/CodeSignTool.sh" && ln -s "/codesign/CodeSignTool.sh" "/usr/bin/codesign"

COPY ./codesign-tool/ /codesign
COPY ./entrypoint.sh /entrypoint.sh
COPY ./examples /codesign/examples

RUN chmod +x /entrypoint.sh
RUN chmod +x /codesign/CodeSignTool.sh
RUN mkdir -p /codesign/output

WORKDIR /codesign

ENTRYPOINT ["/entrypoint.sh"]
