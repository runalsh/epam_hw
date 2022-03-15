FROM python:3.7-slim as base
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /app
COPY . .
RUN pip3 install --no-cache-dir -r requirements.txt
# RUN pip3 install --no-cache-dir django psycopg2
# RUN apt install --no-install-recommends postgresql-client
RUN sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['*'\]/g" /app/lib_catalog/settings.py


