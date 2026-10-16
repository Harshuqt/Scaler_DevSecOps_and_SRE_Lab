FROM python:3.13-alpine
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY app/app.py .
USER appuser
EXPOSE 80
CMD ["python", "app.py"]