FROM python:3.9-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.9-slim
RUN adduser --disabled-password --gecos "" innovatech_user
WORKDIR /app

COPY --from=builder /root/.local /home/innovatech_user/.local
COPY . .

ENV PATH=/home/innovatech_user/.local/bin:$PATH
RUN chown -R innovatech_user:innovatech_user /app
USER innovatech_user

EXPOSE 5000
CMD ["python", "app.py"]