FROM python:3.12.10-alpine

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    FLASK_APP=api.py \
    FLASK_ENV=production

WORKDIR /app

RUN apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    apk del .build-deps

COPY api.py ./

EXPOSE 5000

CMD ["python", "api.py"]