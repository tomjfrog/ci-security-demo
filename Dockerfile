# Stage 1: Unpack the pre-built application from the zip archive
FROM node:22 AS unpacker

WORKDIR /juice-shop

# Copy the specific distributable zip file created by `npm run package`
COPY dist/juice-shop-18.0.0.zip .

# Unzip, move contents from the created sub-directory, and clean up.
# This is the most robust method as it preserves the app's internal structure.
RUN unzip *.zip
RUN mv juice-shop*/* .
RUN rmdir juice-shop_*
RUN rm *.zip

# Re-create necessary runtime directories and set permissions
RUN mkdir logs
RUN chown -R 65532 logs
RUN chgrp -R 0 ftp/ frontend/dist/ logs/ data/ i18n/
RUN chmod -R g=u ftp/ frontend/dist/ logs/ data/ i18n/

# Remove files not needed in production to keep the image slim
RUN rm data/chatbot/botDefaultTrainingData.json || true
RUN rm ftp/legal.md || true
RUN rm i18n/*.json || true


# Stage 2: Final minimal image using distroless
FROM gcr.io/distroless/nodejs22-debian12

# Application metadata
ARG BUILD_DATE
ARG VCS_REF
LABEL maintainer="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
    org.opencontainers.image.title="OWASP Juice Shop" \
    org.opencontainers.image.description="Probably the most modern and sophisticated insecure web application" \
    org.opencontainers.image.authors="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
    org.opencontainers.image.vendor="Open Worldwide Application Security Project" \
    org.opencontainers.image.documentation="https://help.owasp-juice.shop" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.version="18.0.0" \
    org.opencontainers.image.url="https://owasp-juice.shop" \
    org.opencontainers.image.source="https://github.com/juice-shop/juice-shop" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE

WORKDIR /juice-shop

# Copy the unpacked and prepared application from the 'unpacker' stage
COPY --from=unpacker --chown=65532:0 /juice-shop .

# Set the non-root user for security
USER 65532

# Expose the application port
EXPOSE 3000

# Define the command to run the application
CMD ["/juice-shop/build/app.js"]