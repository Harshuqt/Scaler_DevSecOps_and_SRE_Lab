FROM python:3.13-alpine
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup \
    && rm -rf /usr/local/lib/python3.13/site-packages/*
COPY app/app.py .
USER appuser
EXPOSE 8080
CMD ["python", "app.py"]
