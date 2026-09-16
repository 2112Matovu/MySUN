FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

RUN useradd --create-home appuser
USER appuser

EXPOSE 8000

# $PORT defaults to 8000 above for docker-compose.yml's own nginx sidecar,
# but platforms that run this Dockerfile directly (Render, Cloud Run) pick
# the port and inject their own PORT value — both CMD and HEALTHCHECK must
# read it at container start (shell form), not bake in 8000.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import os,urllib.request; urllib.request.urlopen('http://127.0.0.1:' + os.environ['PORT'] + '/health').read()"

# --forwarded-allow-ips='*' trusts X-Forwarded-For from whatever reverse
# proxy sits in front (the nginx sidecar in docker-compose.yml, or the
# hosting platform's own edge/load balancer) so rate limiting and request
# logs key on the real client IP.
CMD uvicorn app.main:app --host 0.0.0.0 --port $PORT --workers 2 --proxy-headers --forwarded-allow-ips=*
